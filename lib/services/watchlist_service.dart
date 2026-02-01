import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/services/http_service.dart';

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
  final HttpService _httpService = HttpService();

  // Cache duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);
  static const String _lastRefreshKey = 'watchlist_last_availability_refresh';

  /// Get or create a unique device ID for this user (public)
  Future<String> getUserId() async {
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
    bool fetchAvailability = true,
  }) async {
    final userId = await getUserId();

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

    // Fetch availability in background after adding
    if (fetchAvailability) {
      // Don't await - let it run in background
      fetchAndUpdateAvailability(mediaId, isMovie);
    }
  }

  /// Remove item from watchlist
  Future<void> removeFromWatchlist(int mediaId) async {
    final userId = await getUserId();

    await _firestore.collection('users').doc(userId).collection('watchlist').doc(mediaId.toString()).delete();
  }

  /// Get all watchlist items
  Stream<List<WatchlistItem>> getWatchlist() async* {
    final userId = await getUserId();

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
    final userId = await getUserId();

    final doc = await _firestore.collection('users').doc(userId).collection('watchlist').doc(mediaId.toString()).get();

    return doc.exists;
  }

  /// Update availability for a watchlist item
  Future<void> updateAvailability({
    required int mediaId,
    required Map<String, List<int>> availability,
  }) async {
    final userId = await getUserId();

    await _firestore.collection('users').doc(userId).collection('watchlist').doc(mediaId.toString()).update({
      'availability': availability,
      'lastChecked': Timestamp.now(),
    });
  }

  /// Fetch and update availability for a single item
  Future<void> fetchAndUpdateAvailability(int mediaId, bool isMovie) async {
    try {
      final providers = await _httpService.getCategorizedWatchProviders(
        mediaId,
        isMovie,
      );

      final availabilityMap = {
        'streaming': providers.streaming.map((s) => s.providerId).whereType<int>().toList(),
        'rent': providers.rent.map((s) => s.providerId).whereType<int>().toList(),
        'buy': providers.buy.map((s) => s.providerId).whereType<int>().toList(),
      };

      await updateAvailability(
        mediaId: mediaId,
        availability: availabilityMap,
      );
    } catch (e) {
      // Silently fail - availability will be fetched on next refresh
    }
  }

  /// Check if availability cache is stale (older than 24 hours)
  Future<bool> isAvailabilityCacheStale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefresh = prefs.getInt(_lastRefreshKey);

    if (lastRefresh == null) return true;

    final lastRefreshDate = DateTime.fromMillisecondsSinceEpoch(lastRefresh);
    return DateTime.now().difference(lastRefreshDate) > _cacheDuration;
  }

  /// Update the last refresh timestamp
  Future<void> updateLastRefreshTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
  }
}
