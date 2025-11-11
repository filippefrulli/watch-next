import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_review/in_app_review.dart';

class FeedbackService {
  static const String _successfulQueriesKey = 'successful_queries_count';
  static const String _hasShownFeedbackDialogKey = 'has_shown_feedback_dialog';
  static const int _queriesBeforePrompt = 3;

  /// Increment the successful query counter
  static Future<void> incrementSuccessfulQuery() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_successfulQueriesKey) ?? 0;
    await prefs.setInt(_successfulQueriesKey, currentCount + 1);
  }

  /// Check if we should show the feedback dialog
  static Future<bool> shouldShowFeedbackDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_hasShownFeedbackDialogKey) ?? false;

    if (hasShown) return false;

    final count = prefs.getInt(_successfulQueriesKey) ?? 0;
    return count >= _queriesBeforePrompt;
  }

  /// Mark that we've shown the feedback dialog
  static Future<void> markFeedbackDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasShownFeedbackDialogKey, true);
  }

  /// Request in-app review
  static Future<void> requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // Fallback to opening store listing if in-app review not available
      await inAppReview.openStoreListing(
        appStoreId: 'YOUR_APP_STORE_ID', // TODO: Replace with actual App Store ID
      );
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
      print('Error submitting feedback: $e');
      return false;
    }
  }

  /// Reset the counter (useful for testing)
  static Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_successfulQueriesKey);
    await prefs.remove(_hasShownFeedbackDialogKey);
  }
}
