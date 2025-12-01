import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/main.dart' show navigatorKey;
import 'package:watch_next/pages/watchlist_page.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _fcmTokenKey = 'fcm_token';
  static const String _permissionRequestedKey = 'notification_permission_requested';

  /// Initialize notification service and set up listeners
  static Future<void> initialize() async {
    // Request permission on iOS (Android auto-grants)
    await _requestPermission();

    // Get and store FCM token
    await _getAndStoreToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Request notification permission (iOS specific, Android auto-grants)
  static Future<bool> _requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool(_permissionRequestedKey) ?? false;

    if (hasRequested) {
      // Already requested, just check current status
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await prefs.setBool(_permissionRequestedKey, true);

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get FCM token and store in Firestore
  static Future<void> _getAndStoreToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);

        // Save locally for reference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_fcmTokenKey, token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Handle token refresh
  static Future<void> _onTokenRefresh(String newToken) async {
    await _saveTokenToFirestore(newToken);

    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, newToken);
  }

  /// Save FCM token to Firestore user document
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle messages received while app is in foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // You could show an in-app banner here if desired
  }

  /// Handle notification tap (when app is in background or terminated)
  static void _handleMessageTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');

    // Navigate to watchlist page
    final context = navigatorKey.currentContext;
    if (context != null && message.data['type'] == 'watchlist_update') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WatchlistPage(),
        ),
      );
    }
  }

  /// Check if notification permission has been granted
  static Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Manually request permission (for showing dialog first)
  static Future<bool> requestPermissionWithDialog(BuildContext context) async {
    // Capture theme color before any async gaps
    final dialogColor = Theme.of(context).colorScheme.tertiary;

    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool(_permissionRequestedKey) ?? false;

    if (hasRequested) {
      // Already requested before
      return await hasPermission();
    }

    // Check if context is still valid after async gap
    if (!context.mounted) return false;

    // Show dialog explaining why we need permission
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogColor,
        title: const Text(
          'Enable Notifications?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Get notified when movies on your watchlist become available on your streaming services.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enable', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await prefs.setBool(_permissionRequestedKey, true);
      final granted = await _requestPermission();
      if (granted) {
        await _getAndStoreToken();
      }
      return granted;
    }

    return false;
  }

  /// Delete FCM token (for logout/account deletion)
  static Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': FieldValue.delete()});
      }

      await _messaging.deleteToken();
      await prefs.remove(_fcmTokenKey);
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
