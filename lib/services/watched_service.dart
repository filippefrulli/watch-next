import 'package:sqflite/sqflite.dart';
import 'package:watch_next/utils/database.dart';

class WatchedItem {
  final int mediaId;
  final String title;
  final bool isMovie;
  final String? posterPath;
  final int rating; // 1–10
  final DateTime dateWatched;
  final String? overview;
  final List<String> genreNames; // e.g. ['Action', 'Drama']

  WatchedItem({
    required this.mediaId,
    required this.title,
    required this.isMovie,
    this.posterPath,
    required this.rating,
    required this.dateWatched,
    this.overview,
    this.genreNames = const [],
  });

  factory WatchedItem.fromMap(Map<String, dynamic> map) {
    final raw = map['genre_names'] as String?;
    return WatchedItem(
      mediaId: map['media_id'] as int,
      title: map['title'] as String,
      isMovie: (map['is_movie'] as int) == 1,
      posterPath: map['poster_path'] as String?,
      rating: map['rating'] as int,
      dateWatched: DateTime.parse(map['date_watched'] as String),
      overview: map['overview'] as String?,
      genreNames: (raw != null && raw.isNotEmpty) ? raw.split(',') : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'media_id': mediaId,
      'title': title,
      'is_movie': isMovie ? 1 : 0,
      'poster_path': posterPath,
      'rating': rating,
      'date_watched': dateWatched.toIso8601String(),
      'overview': overview,
      'genre_names': genreNames.isNotEmpty ? genreNames.join(',') : null,
    };
  }

  WatchedItem copyWith({
    int? rating,
    DateTime? dateWatched,
  }) {
    return WatchedItem(
      mediaId: mediaId,
      title: title,
      isMovie: isMovie,
      posterPath: posterPath,
      rating: rating ?? this.rating,
      dateWatched: dateWatched ?? this.dateWatched,
      overview: overview,
      genreNames: genreNames,
    );
  }
}

class WatchedService {
  static const String _table = 'watched';

  Future<Database> get _db async => (await DatabaseHelper.instance.database)!;

  /// Add or replace a watched entry
  Future<void> markAsWatched(WatchedItem item) async {
    final db = await _db;
    await db.insert(
      _table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove from watched list
  Future<void> removeFromWatched(int mediaId) async {
    final db = await _db;
    await db.delete(_table, where: 'media_id = ?', whereArgs: [mediaId]);
  }

  /// Check if an item is in the watched list
  Future<bool> isWatched(int mediaId) async {
    final db = await _db;
    final result = await db.query(_table, where: 'media_id = ?', whereArgs: [mediaId]);
    return result.isNotEmpty;
  }

  /// Get the watched entry for a specific item (null if not watched)
  Future<WatchedItem?> getWatchedItem(int mediaId) async {
    final db = await _db;
    final result = await db.query(_table, where: 'media_id = ?', whereArgs: [mediaId]);
    if (result.isEmpty) return null;
    return WatchedItem.fromMap(result.first);
  }

  /// Get all watched items, ordered by date descending
  Future<List<WatchedItem>> getWatchedList() async {
    final db = await _db;
    final result = await db.query(_table, orderBy: 'date_watched DESC');
    return result.map((m) => WatchedItem.fromMap(m)).toList();
  }

  /// Get watched items filtered by type
  Future<List<WatchedItem>> getWatchedListFiltered({
    bool? isMovie,
    int? minRating,
    int? maxRating,
    String sortBy = 'date_watched',
    bool descending = true,
  }) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (isMovie != null) {
      conditions.add('is_movie = ?');
      args.add(isMovie ? 1 : 0);
    }
    if (minRating != null) {
      conditions.add('rating >= ?');
      args.add(minRating);
    }
    if (maxRating != null) {
      conditions.add('rating <= ?');
      args.add(maxRating);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final order = '$sortBy ${descending ? 'DESC' : 'ASC'}';

    final result = await db.query(_table, where: where, whereArgs: args.isEmpty ? null : args, orderBy: order);
    return result.map((m) => WatchedItem.fromMap(m)).toList();
  }

  /// Update rating and/or date for an existing entry
  Future<void> updateWatchedItem(int mediaId, {int? rating, DateTime? dateWatched}) async {
    final db = await _db;
    final updates = <String, dynamic>{};
    if (rating != null) updates['rating'] = rating;
    if (dateWatched != null) updates['date_watched'] = dateWatched.toIso8601String();
    if (updates.isEmpty) return;
    await db.update(_table, updates, where: 'media_id = ?', whereArgs: [mediaId]);
  }

  // ── Stats helpers ──────────────────────────────────────────────────────

  /// Total count of watched items
  Future<int> getTotalCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Average rating across all watched items
  Future<double> getAverageRating() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT AVG(rating) as avg FROM $_table');
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  /// Count of movies vs shows
  Future<Map<String, int>> getTypeBreakdown() async {
    final db = await _db;
    final movies = await db.rawQuery('SELECT COUNT(*) as count FROM $_table WHERE is_movie = 1');
    final shows = await db.rawQuery('SELECT COUNT(*) as count FROM $_table WHERE is_movie = 0');
    return {
      'movies': (movies.first['count'] as int?) ?? 0,
      'shows': (shows.first['count'] as int?) ?? 0,
    };
  }

  /// Rating distribution: map of rating (1–10) → count, optionally filtered by type
  Future<Map<int, int>> getRatingDistribution({bool? isMovie}) async {
    final db = await _db;
    final where = isMovie == null ? '' : ' WHERE is_movie = ${isMovie ? 1 : 0}';
    final result = await db.rawQuery(
      'SELECT rating, COUNT(*) as count FROM $_table$where GROUP BY rating ORDER BY rating',
    );
    final map = <int, int>{};
    for (final row in result) {
      map[row['rating'] as int] = row['count'] as int;
    }
    return map;
  }

  /// Genre breakdown: map of genre name → count, sorted by count descending.
  /// Pass [isMovie] to filter to movies (true) or shows (false) only.
  Future<Map<String, int>> getGenreBreakdown({bool? isMovie}) async {
    final db = await _db;
    final result = await db.query(
      _table,
      columns: ['genre_names'],
      where: isMovie == null ? null : 'is_movie = ?',
      whereArgs: isMovie == null ? null : [isMovie ? 1 : 0],
    );
    final counts = <String, int>{};
    for (final row in result) {
      final raw = row['genre_names'] as String?;
      if (raw == null || raw.isEmpty) continue;
      for (final genre in raw.split(',')) {
        final g = genre.trim();
        if (g.isNotEmpty) counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  /// Most recently watched item
  Future<WatchedItem?> getMostRecentItem() async {
    final db = await _db;
    final result = await db.query(_table, orderBy: 'date_watched DESC', limit: 1);
    if (result.isEmpty) return null;
    return WatchedItem.fromMap(result.first);
  }

  /// Titles rated >= threshold (for AI prompt taste signals)
  Future<List<WatchedItem>> getHighlyRatedItems({int threshold = 7}) async {
    final db = await _db;
    final result = await db.query(_table, where: 'rating >= ?', whereArgs: [threshold], orderBy: 'rating DESC');
    return result.map((m) => WatchedItem.fromMap(m)).toList();
  }

  /// Titles rated below threshold (for AI prompt negative signals)
  Future<List<WatchedItem>> getLowRatedItems({int threshold = 5}) async {
    final db = await _db;
    final result = await db.query(_table, where: 'rating < ?', whereArgs: [threshold], orderBy: 'rating ASC');
    return result.map((m) => WatchedItem.fromMap(m)).toList();
  }

  /// All watched media IDs (for exclusion from AI)
  Future<List<int>> getAllWatchedIds() async {
    final db = await _db;
    final result = await db.query(_table, columns: ['media_id']);
    return result.map((m) => m['media_id'] as int).toList();
  }
}
