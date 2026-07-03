import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_review/in_app_review.dart';

class FeedbackService {
  static const String _successfulQueriesKey = 'successful_queries_count';
  static const String _legacyHasShownDialogKey = 'has_shown_feedback_dialog';
  static const String _nextPromptAtKey = 'next_review_prompt_at';
  static const String _promptTimestampsKey = 'review_prompt_timestamps';
  static const int _queriesBeforeFirstPrompt = 7;
  static const int _queriesBetweenPrompts = 10;
  static const int _maxPromptsPerYear = 3;

  static const String _appStoreId = '6450368827'; // Apple App Store ID
  static const String _googlePlayId = 'com.filippefrulli.watch_next'; // Google Play package name

  /// Increment the successful query counter
  static Future<void> incrementSuccessfulQuery() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_successfulQueriesKey) ?? 0;
    await prefs.setInt(_successfulQueriesKey, currentCount + 1);
  }

  /// Check if we should show the feedback dialog
  static Future<bool> shouldShowFeedbackDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_successfulQueriesKey) ?? 0;

    // Migrate installs that used the old once-ever flag: count it as one past
    // prompt and re-arm, instead of never asking again.
    if (prefs.getBool(_legacyHasShownDialogKey) ?? false) {
      await prefs.remove(_legacyHasShownDialogKey);
      await prefs.setInt(_nextPromptAtKey, count + _queriesBetweenPrompts);
      return false;
    }

    final nextPromptAt = prefs.getInt(_nextPromptAtKey) ?? _queriesBeforeFirstPrompt;
    if (count < nextPromptAt) return false;

    return await _promptsInLastYear(prefs) < _maxPromptsPerYear;
  }

  /// Mark that we've shown the feedback dialog and re-arm the next prompt
  static Future<void> markFeedbackDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_successfulQueriesKey) ?? 0;
    await prefs.setInt(_nextPromptAtKey, count + _queriesBetweenPrompts);

    final timestamps = prefs.getStringList(_promptTimestampsKey) ?? [];
    timestamps.add(DateTime.now().millisecondsSinceEpoch.toString());
    await prefs.setStringList(_promptTimestampsKey, timestamps);
  }

  /// Count prompts shown in the last 365 days, pruning older entries
  static Future<int> _promptsInLastYear(SharedPreferences prefs) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
    final timestamps = prefs.getStringList(_promptTimestampsKey) ?? [];
    final recent = timestamps.where((t) => (int.tryParse(t) ?? 0) >= cutoff).toList();

    if (recent.length != timestamps.length) {
      await prefs.setStringList(_promptTimestampsKey, recent);
    }
    return recent.length;
  }

  /// Request in-app review
  static Future<void> requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // Fallback to opening store listing if in-app review not available
      if (Platform.isIOS) {
        await inAppReview.openStoreListing(appStoreId: _appStoreId);
      } else {
        await inAppReview.openStoreListing(appStoreId: _googlePlayId);
      }
    }
  }

  /// Submit feedback to Firestore
  static Future<bool> submitFeedback(String feedbackText) async {
    try {
      if (feedbackText.trim().isEmpty) return false;

      await FirebaseFirestore.instance.collection('feedback').add({
        'text': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset the counter (useful for testing)
  static Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_successfulQueriesKey);
    await prefs.remove(_legacyHasShownDialogKey);
    await prefs.remove(_nextPromptAtKey);
    await prefs.remove(_promptTimestampsKey);
  }
}
