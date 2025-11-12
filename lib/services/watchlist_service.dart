import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/services/notification_service.dart';

class WatchlistItem {
  final int mediaId;
  final String title;
  final bool isMovie;
  final String? posterPath;
  final DateTime dateAdded;
  final DateTime? lastChecked;
  final Map<String, List<int>> availability; // {streaming: [providerId1, ...], rent: [...], buy: [...]}

  WatchlistItem({
    required this.mediaId,
    required this.title,
    required this.isMovie,
    this.posterPath,
    required this.dateAdded,
    this.lastChecked,
    required this.availability,
  });

  factory WatchlistItem.fromFirestore(Map<String, dynamic> data) {
    return WatchlistItem(
      mediaId: data['mediaId'] as int,
      title: data['title'] as String,
      isMovie: data['isMovie'] as bool,
      posterPath: data['posterPath'] as String?,
      dateAdded: (data['dateAdded'] as Timestamp).toDate(),
      lastChecked: data['lastChecked'] != null ? (data['lastChecked'] as Timestamp).toDate() : null,
      availability: Map<String, List<int>>.from(
        (data['availability'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, List<int>.from(value as List)),
        ),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mediaId': mediaId,
      'title': title,
      'isMovie': isMovie,
      'posterPath': posterPath,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'lastChecked': lastChecked != null ? Timestamp.fromDate(lastChecked!) : null,
      'availability': availability,
    };
  }

  /// Check if item is currently available on any of the user's services
  bool isAvailable(List<int> userServiceIds) {
    // Only check streaming availability, not rent or buy
    final streamingProviders = availability['streaming'] ?? [];
    return streamingProviders.any((id) => userServiceIds.contains(id));
  }

  /// Copy with updated fields
  WatchlistItem copyWith({
    int? mediaId,
    String? title,
    bool? isMovie,
    String? posterPath,
    DateTime? dateAdded,
    DateTime? lastChecked,
    Map<String, List<int>>? availability,
  }) {
    return WatchlistItem(
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      isMovie: isMovie ?? this.isMovie,
      posterPath: posterPath ?? this.posterPath,
      dateAdded: dateAdded ?? this.dateAdded,
      lastChecked: lastChecked ?? this.lastChecked,
      availability: availability ?? this.availability,
    );
  }
}

class WatchlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create a unique device ID for this user
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      // Generate a unique ID for this device
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('user_id', userId);
    }

    return userId;
  }

  /// Add item to watchlist
  Future<void> addToWatchlist({
    required int mediaId,
    required String title,
    required bool isMovie,
    String? posterPath,
    BuildContext? context,
  }) async {
    final userId = await _getUserId();

    final item = WatchlistItem(
      mediaId: mediaId,
      title: title,
      isMovie: isMovie,
      posterPath: posterPath,
      dateAdded: DateTime.now(),
      availability: {'streaming': [], 'rent': [], 'buy': []},
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(mediaId.toString())
        .set(item.toFirestore());

    // Request notification permission after first watchlist item
    if (context != null) {
      final watchlistSnapshot = await _firestore.collection('users').doc(userId).collection('watchlist').limit(2).get();

      // If this is the first or second item, request permission
      if (watchlistSnapshot.docs.length <= 2) {
        final hasPermission = await NotificationService.hasPermission();
        if (!hasPermission && context.mounted) {
          // Show permission dialog after a brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              NotificationService.requestPermissionWithDialog(context);
            }
          });
        }
      }
    }
  }

  /// Remove item from watchlist
  Future<void> removeFromWatchlist(int mediaId) async {
    final userId = await _getUserId();

    await _firestore.collection('users').doc(userId).collection('watchlist').doc(mediaId.toString()).delete();
  }

  /// Get all watchlist items
  Stream<List<WatchlistItem>> getWatchlist() async* {
    final userId = await _getUserId();

    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WatchlistItem.fromFirestore(doc.data());
      }).toList();
    });
  }

  /// Check if item is in watchlist
  Future<bool> isInWatchlist(int mediaId) async {
    final userId = await _getUserId();

    final doc = await _firestore.collection('users').doc(userId).collection('watchlist').doc(mediaId.toString()).get();

    return doc.exists;
  }

  /// Update availability for a watchlist item
  Future<void> updateAvailability({
    required int mediaId,
    required Map<String, List<int>> availability,
  }) async {
    final userId = await _getUserId();

    await _firestore.collection('users').doc(userId).collection('watchlist').doc(mediaId.toString()).update({
      'availability': availability,
      'lastChecked': Timestamp.now(),
    });
  }
}
