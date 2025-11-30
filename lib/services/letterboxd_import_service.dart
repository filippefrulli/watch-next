import 'dart:io';
import 'package:csv/csv.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/objects/search_results.dart';

class LetterboxdImportService {
  final WatchlistService _watchlistService = WatchlistService();
  final HttpService _httpService = HttpService();

  /// Import watchlist from Letterboxd CSV export
  /// Returns (successCount, skippedCount, failedCount)
  Future<(int, int, int)> importFromCsv(File file) async {
    try {
      // Read the CSV file
      final input = file.readAsStringSync();
      final csvData = const CsvToListConverter().convert(input, eol: '\n');

      if (csvData.isEmpty) {
        return (0, 0, 0);
      }

      // Find column indices - Letterboxd format: Date,Name,Year,Letterboxd URI
      final headers = csvData[0].map((h) => h.toString().toLowerCase()).toList();
      final nameIndex = headers.indexOf('name');
      final yearIndex = headers.indexOf('year');

      if (nameIndex == -1 || yearIndex == -1) {
        throw Exception('Invalid Letterboxd CSV format');
      }

      int successCount = 0;
      int skippedCount = 0;
      int failedCount = 0;

      // Process each row (skip header)
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length <= nameIndex || row.length <= yearIndex) {
          failedCount++;
          continue;
        }

        final title = row[nameIndex].toString();
        final year = row[yearIndex].toString();

        if (title.isEmpty) {
          failedCount++;
          continue;
        }

        try {
          // Letterboxd is movies only, so always search for movies
          final result = await _httpService.findMovieByTitle(title, year);

          // Check if we got a valid result
          int? mediaId;
          String? resultTitle;
          String? posterPath;

          if (result is Results) {
            mediaId = result.id;
            resultTitle = result.title ?? result.originalTitle;
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
            isMovie: true, // Letterboxd is movies only
            posterPath: posterPath,
          );

          successCount++;
        } catch (e) {
          print('Error importing $title: $e');
          failedCount++;
        }

        // Add a small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return (successCount, skippedCount, failedCount);
    } catch (e) {
      print('Error reading CSV: $e');
      rethrow;
    }
  }
}
