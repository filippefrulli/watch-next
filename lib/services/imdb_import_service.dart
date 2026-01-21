import 'dart:io';
import 'package:csv/csv.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/objects/search_results.dart';
import 'package:watch_next/objects/series_search_results.dart';

class ImdbImportService {
  final WatchlistService _watchlistService = WatchlistService();
  final HttpService _httpService = HttpService();

  /// Import watchlist from IMDb CSV export
  /// Returns (successCount, skippedCount, failedCount)
  Future<(int, int, int)> importFromCsv(File file) async {
    try {
      // Read the CSV file
      final input = file.readAsStringSync();
      final csvData = const CsvToListConverter().convert(input, eol: '\n');

      if (csvData.isEmpty) {
        return (0, 0, 0);
      }

      // Find column indices
      final headers = csvData[0].map((h) => h.toString().toLowerCase()).toList();
      final titleIndex = headers.indexOf('title');
      final titleTypeIndex = headers.indexOf('title type');
      final yearIndex = headers.indexOf('year');

      if (titleIndex == -1 || titleTypeIndex == -1 || yearIndex == -1) {
        throw Exception('Invalid IMDb CSV format');
      }

      int successCount = 0;
      int skippedCount = 0;
      int failedCount = 0;

      // Process each row (skip header)
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length <= titleIndex || row.length <= titleTypeIndex || row.length <= yearIndex) {
          failedCount++;
          continue;
        }

        final title = row[titleIndex].toString();
        final titleType = row[titleTypeIndex].toString().toLowerCase();
        final year = row[yearIndex].toString();

        if (title.isEmpty || year.isEmpty) {
          failedCount++;
          continue;
        }

        // Determine if it's a movie or TV show
        final isMovie = titleType == 'movie';

        try {
          // Search TMDB for the title
          dynamic result;
          if (isMovie) {
            result = await _httpService.findMovieByTitle(title, year);
          } else {
            result = await _httpService.findShowByTitle(title, year);
          }

          // Check if we got a valid result
          int? mediaId;
          String? resultTitle;
          String? posterPath;

          if (isMovie && result is Results) {
            mediaId = result.id;
            resultTitle = result.title ?? result.originalTitle;
            posterPath = result.posterPath;
          } else if (!isMovie && result is SeriesResults) {
            mediaId = result.id;
            resultTitle = result.name ?? result.originalTitle;
            posterPath = result.posterPath;
          }

          if (mediaId == null) {
            failedCount++;
            continue;
          }

          // Check if already in watchlist
          final isInWatchlist = await _watchlistService.isInWatchlist(mediaId);
          if (isInWatchlist) {
            skippedCount++;
            continue;
          }

          // Add to watchlist
          await _watchlistService.addToWatchlist(
            mediaId: mediaId,
            title: resultTitle ?? title,
            isMovie: isMovie,
            posterPath: posterPath,
          );

          successCount++;
        } catch (e) {
          failedCount++;
        }

        // Add a small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return (successCount, skippedCount, failedCount);
    } catch (e) {
      rethrow;
    }
  }
}
