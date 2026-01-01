import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:watch_next/main.dart' show navigatorKey;
import 'package:watch_next/pages/watchlist_page.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _weeklyReminderEnabledKey = 'weekly_reminder_enabled';
  static const int _weeklyReminderId = 100;

  /// Initialize notification service
  static Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Schedule weekly reminder if enabled (default: enabled)
    await _scheduleWeeklyReminderIfEnabled();
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  /// Handle local notification tap
  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    final context = navigatorKey.currentContext;
    if (context != null && response.payload == 'weekly_reminder') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WatchlistPage(),
        ),
      );
    }
  }

  /// Schedule weekly Friday reminder if enabled
  static Future<void> _scheduleWeeklyReminderIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_weeklyReminderEnabledKey) ?? true; // Default: enabled

    if (isEnabled) {
      await scheduleWeeklyFridayReminder();
    }
  }

  /// Schedule a weekly notification for Friday at 6 PM local time
  static Future<void> scheduleWeeklyFridayReminder() async {
    // Cancel any existing weekly reminder first
    await _localNotifications.cancel(_weeklyReminderId);

    // Get translated strings
    final title = 'notification_title'.tr();
    final body = 'notification_body'.tr();

    const androidDetails = AndroidNotificationDetails(
      'weekly_reminder',
      'Weekly Reminder',
      channelDescription: 'Weekly reminder to pick something to watch',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/launcher_icon',
      color: Colors.orange,
      colorized: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      _weeklyReminderId,
      title,
      body,
      _nextFriday(18, 0), // Friday at 6 PM
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeats weekly!
      payload: 'weekly_reminder',
    );

    debugPrint('Weekly Friday reminder scheduled');
  }

  /// Calculate the next Friday at the specified hour and minute
  static tz.TZDateTime _nextFriday(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Find next Friday
    while (scheduled.weekday != DateTime.friday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Cancel weekly reminder
  static Future<void> cancelWeeklyReminder() async {
    await _localNotifications.cancel(_weeklyReminderId);
    debugPrint('Weekly Friday reminder cancelled');
  }

  /// Enable or disable weekly reminder
  static Future<void> setWeeklyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklyReminderEnabledKey, enabled);

    if (enabled) {
      await scheduleWeeklyFridayReminder();
    } else {
      await cancelWeeklyReminder();
    }
  }

  /// Check if weekly reminder is enabled
  static Future<bool> isWeeklyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weeklyReminderEnabledKey) ?? true; // Default: enabled
  }

  /// TEST ONLY: Show the weekly reminder notification immediately
  static Future<void> testWeeklyReminder() async {
    // Get translated strings
    final title = 'notification_title'.tr();
    final body = 'notification_body'.tr();

    const androidDetails = AndroidNotificationDetails(
      'weekly_reminder',
      'Weekly Reminder',
      channelDescription: 'Weekly reminder to pick something to watch',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/launcher_icon',
      color: Colors.orange,
      colorized: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999, // Different ID for test
      title,
      body,
      notificationDetails,
      payload: 'weekly_reminder',
    );

    debugPrint('Test notification sent!');
  }
}
