import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for logging user actions to Firestore for analytics
class UserActionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current user ID
  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('user_id', userId);
    }

    return userId;
  }

  /// Initialize user document on first app open
  /// This ensures we have a record of every user, even if they don't perform actions
  static Future<void> initializeUser() async {
    if (kDebugMode) return;

    try {
      final userId = await _getUserId();
      final userDoc = _firestore.collection('users').doc(userId);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // First time user - create the document
        await userDoc.set({
          'created_at': FieldValue.serverTimestamp(),
          'first_open': FieldValue.serverTimestamp(),
          'last_open': FieldValue.serverTimestamp(),
        });
      } else {
        // Returning user - update last_open
        await userDoc.update({
          'last_open': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience for analytics
    }
  }

  /// Log a user action to Firestore
  ///
  /// [actionName] - The name of the action (e.g., 'recommendation_requested')
  /// [details] - Optional map of action-specific details
  static Future<void> logAction(
    String actionName, {
    Map<String, dynamic>? details,
  }) async {
    if (kDebugMode) return;

    try {
      final userId = await _getUserId();

      final actionData = {
        'action_name': actionName,
        'timestamp': FieldValue.serverTimestamp(),
        if (details != null) 'details': details,
      };

      await _firestore.collection('users').doc(userId).collection('actions').add(actionData);
    } catch (e) {
      // Silently fail - don't interrupt user experience for analytics
    }
  }

  // ========== Action-specific logging methods ==========

  /// Log when a recommendation is requested
  static Future<void> logRecommendationRequested({
    required String query,
    required String type, // 'movie' or 'show'
    required bool includeRentals,
    required bool includePurchases,
    required List<String> streamingServices,
  }) async {
    await logAction('recommendation_requested', details: {
      'query': query,
      'type': type,
      'include_rentals': includeRentals,
      'include_purchases': includePurchases,
      'streaming_services': streamingServices,
    });
  }

  /// Log when an item is added to the watchlist
  static Future<void> logWatchlistAdd({
    required int mediaId,
    required String title,
    required String type, // 'movie' or 'show'
    required String source, // 'recommendation', 'search', 'playlist', 'media_detail'
  }) async {
    await logAction('watchlist_add', details: {
      'media_id': mediaId,
      'title': title,
      'type': type,
      'source': source,
    });
  }

  /// Log when an item is removed from the watchlist
  static Future<void> logWatchlistRemove({
    required int mediaId,
    required String title,
    required String type, // 'movie' or 'show'
  }) async {
    await logAction('watchlist_remove', details: {
      'media_id': mediaId,
      'title': title,
      'type': type,
    });
  }

  /// Log when watchlist is imported
  static Future<void> logWatchlistImported({
    required String source, // 'imdb' or 'letterboxd'
    required int successCount,
    required int failedCount,
    required int skippedCount,
  }) async {
    await logAction('watchlist_imported', details: {
      'source': source,
      'success_count': successCount,
      'failed_count': failedCount,
      'skipped_count': skippedCount,
    });
  }

  /// Log when a search is performed
  static Future<void> logSearchPerformed({
    required String query,
    required String type, // 'movie' or 'show'
    required int resultsCount,
  }) async {
    await logAction('search_performed', details: {
      'query': query,
      'type': type,
      'results_count': resultsCount,
    });
  }

  /// Log when a search result is selected
  static Future<void> logSearchResultSelected({
    required int mediaId,
    required String title,
    required String type, // 'movie' or 'show'
    required int positionInList,
  }) async {
    await logAction('search_result_selected', details: {
      'media_id': mediaId,
      'title': title,
      'type': type,
      'position_in_list': positionInList,
    });
  }

  /// Log when a playlist is viewed
  static Future<void> logPlaylistViewed({
    required String playlistId,
    required String playlistTitle,
    required int itemsCount,
  }) async {
    await logAction('playlist_viewed', details: {
      'playlist_id': playlistId,
      'playlist_title': playlistTitle,
      'items_count': itemsCount,
    });
  }

  /// Log when a playlist item is selected
  static Future<void> logPlaylistItemSelected({
    required String playlistId,
    required int mediaId,
    required String title,
    required String type, // 'movie' or 'show'
    required int positionInList,
  }) async {
    await logAction('playlist_item_selected', details: {
      'playlist_id': playlistId,
      'media_id': mediaId,
      'title': title,
      'type': type,
      'position_in_list': positionInList,
    });
  }

  /// Log when language is changed
  static Future<void> logLanguageChanged({
    required String fromLanguage,
    required String toLanguage,
  }) async {
    await logAction('language_changed', details: {
      'from_language': fromLanguage,
      'to_language': toLanguage,
    });
  }

  /// Log when region is changed
  static Future<void> logRegionChanged({
    required String fromRegion,
    required String toRegion,
  }) async {
    await logAction('region_changed', details: {
      'from_region': fromRegion,
      'to_region': toRegion,
    });
  }

  /// Log when streaming services are updated
  static Future<void> logStreamingServicesUpdated() async {
    await logAction('streaming_services_updated');
  }

  /// Log when a tab is selected
  static Future<void> logTabSelected({
    required String tabName,
  }) async {
    await logAction('tab_selected', details: {
      'tab_name': tabName,
    });
  }

  /// Log when a button is pressed
  static Future<void> logButtonPressed({
    required String buttonName,
  }) async {
    await logAction('button_pressed', details: {
      'button_name': buttonName,
    });
  }
}
