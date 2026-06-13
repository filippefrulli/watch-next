import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
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
class RatingsService {
  static final http.Client _client = http.Client();

  // Small in-memory cache so swiping back and forth doesn't re-hit OMDb.
  static final Map<String, ExternalRatings> _cache = {};

  static Future<ExternalRatings> fetchByImdbId(String? imdbId) async {
    if (omdbApiKey.isEmpty || imdbId == null || imdbId.isEmpty) {
      return const ExternalRatings();
    }
    if (_cache.containsKey(imdbId)) return _cache[imdbId]!;

    try {
      final response = await _client
          .get(Uri.https('www.omdbapi.com', '/', {'apikey': omdbApiKey, 'i': imdbId}))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const ExternalRatings();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['Response'] == 'False') return const ExternalRatings();

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

      final result = ExternalRatings(imdb: imdb, rottenTomatoes: rt, metacritic: meta);
      _cache[imdbId] = result;
      return result;
    } catch (e) {
      log('Error fetching OMDb ratings: $e');
      return const ExternalRatings();
    }
  }
}
