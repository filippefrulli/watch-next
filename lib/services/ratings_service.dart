import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:watch_next/utils/database.dart';
import 'package:watch_next/utils/secrets.dart';

/// Aggregated external ratings for a title, sourced from OMDb.
class ExternalRatings {
  /// IMDb rating out of 10, e.g. "8.7".
  final String? imdb;

  /// Rotten Tomatoes score as a percentage, e.g. "94%".
  final String? rottenTomatoes;

  /// Metacritic score out of 100, e.g. "78".
  final String? metacritic;

  const ExternalRatings({this.imdb, this.rottenTomatoes, this.metacritic});

  bool get hasAny => imdb != null || rottenTomatoes != null || metacritic != null;
}

/// Fetches IMDb / Rotten Tomatoes / Metacritic scores from OMDb.
///
/// Requires an [omdbApiKey] in secrets.dart. If the key is empty (or any error
/// occurs) it returns empty ratings so the UI simply hides the extra scores.
///
/// OMDb caps free keys at 1000 requests/day, so results are cached in two
/// layers to stay well under quota:
///  - an in-memory map for the current session (zero-cost re-reads on swipe),
///  - a persistent SQLite table that survives app restarts.
/// Scores drift slowly, so cached entries are reused for [_ttl]. Successful
/// lookups — including titles OMDb has no data for — are cached so we never
/// re-request them within the TTL; only transient failures (network/non-200)
/// are left uncached so they can be retried.
class RatingsService {
  static final http.Client _client = http.Client();

  // In-memory cache so swiping back and forth doesn't even hit SQLite.
  static final Map<String, ExternalRatings> _cache = {};

  // How long a persisted rating is considered fresh.
  static const Duration _ttl = Duration(days: 30);

  static Future<ExternalRatings> fetchByImdbId(String? imdbId) async {
    if (omdbApiKey.isEmpty || imdbId == null || imdbId.isEmpty) {
      return const ExternalRatings();
    }

    // 1. Session cache.
    final memoryHit = _cache[imdbId];
    if (memoryHit != null) return memoryHit;

    // 2. Persistent cache (survives restarts).
    final cached = await _readFromCache(imdbId);
    if (cached != null) {
      _cache[imdbId] = cached;
      return cached;
    }

    // 3. Fetch from OMDb.
    try {
      final response = await _client
          .get(Uri.https('www.omdbapi.com', '/', {'apikey': omdbApiKey, 'i': imdbId}))
          .timeout(const Duration(seconds: 8));

      // Transient failure — don't cache so the next visit retries.
      if (response.statusCode != 200) return const ExternalRatings();

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Title genuinely unknown to OMDb. Cache the empty result so we don't
      // keep re-requesting it and burning quota.
      if (data['Response'] == 'False') {
        return _store(imdbId, const ExternalRatings());
      }

      String? imdb = (data['imdbRating'] is String && data['imdbRating'] != 'N/A')
          ? data['imdbRating'] as String
          : null;

      String? rt;
      String? meta;
      final ratingsList = data['Ratings'];
      if (ratingsList is List) {
        for (final r in ratingsList) {
          final source = r['Source'];
          final value = r['Value'];
          if (source == 'Rotten Tomatoes' && value is String) rt = value;
          if (source == 'Metacritic' && value is String) {
            // OMDb returns "78/100" → keep just the score.
            meta = value.split('/').first;
          }
        }
      }

      return _store(imdbId, ExternalRatings(imdb: imdb, rottenTomatoes: rt, metacritic: meta));
    } catch (e) {
      log('Error fetching OMDb ratings: $e');
      return const ExternalRatings();
    }
  }

  /// Writes [ratings] to both cache layers and returns it.
  static Future<ExternalRatings> _store(String imdbId, ExternalRatings ratings) async {
    _cache[imdbId] = ratings;
    await _writeToCache(imdbId, ratings);
    return ratings;
  }

  static Future<ExternalRatings?> _readFromCache(String imdbId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return null;
      final rows = await db.query(
        DatabaseHelper.ratingsCacheTable,
        where: '${DatabaseHelper.ratingsImdbId} = ?',
        whereArgs: [imdbId],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final row = rows.first;
      final cachedAt = row[DatabaseHelper.ratingsCachedAt] as int?;
      if (cachedAt == null ||
          DateTime.now().millisecondsSinceEpoch - cachedAt > _ttl.inMilliseconds) {
        return null; // stale → trigger a refetch
      }
      return ExternalRatings(
        imdb: row[DatabaseHelper.ratingsImdb] as String?,
        rottenTomatoes: row[DatabaseHelper.ratingsRottenTomatoes] as String?,
        metacritic: row[DatabaseHelper.ratingsMetacritic] as String?,
      );
    } catch (e) {
      log('Error reading ratings cache: $e');
      return null;
    }
  }

  static Future<void> _writeToCache(String imdbId, ExternalRatings ratings) async {
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return;
      await db.insert(
        DatabaseHelper.ratingsCacheTable,
        {
          DatabaseHelper.ratingsImdbId: imdbId,
          DatabaseHelper.ratingsImdb: ratings.imdb,
          DatabaseHelper.ratingsRottenTomatoes: ratings.rottenTomatoes,
          DatabaseHelper.ratingsMetacritic: ratings.metacritic,
          DatabaseHelper.ratingsCachedAt: DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      log('Error writing ratings cache: $e');
    }
  }
}
