import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching excluded titles per query to avoid duplicate recommendations
/// across multiple "Load More" requests.
class QueryCacheService {
  static const String _cachePrefix = 'query_cache_';
  static const String _cacheKeysKey = 'query_cache_keys';

  /// Generates a unique cache key for a query based on type and request string
  static String _generateCacheKey(int type, String requestString) {
    final input = '${type}_${requestString.toLowerCase().trim()}';
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return '$_cachePrefix${digest.toString()}';
  }

  /// Gets the list of excluded titles for a specific query
  static Future<List<String>> getExcludedTitles(int type, String requestString) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _generateCacheKey(type, requestString);
    final cached = prefs.getStringList(cacheKey);
    return cached ?? [];
  }

  /// Adds new titles to the excluded list for a specific query
  static Future<void> addExcludedTitles(int type, String requestString, List<String> newTitles) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _generateCacheKey(type, requestString);

    // Get existing titles
    final existingTitles = prefs.getStringList(cacheKey) ?? [];

    // Add new titles (avoid duplicates)
    final allTitles = {...existingTitles, ...newTitles}.toList();

    // Save updated list
    await prefs.setStringList(cacheKey, allTitles);

    // Track this cache key for later cleanup
    await _trackCacheKey(cacheKey);
  }

  /// Parses the AI response to extract title names
  static List<String> parseTitlesFromResponse(String response) {
    final titles = <String>[];
    final items = response.split(',,');

    for (final item in items) {
      if (item.isNotEmpty) {
        // Extract title before 'y:' (format is "Title y:Year")
        final yearIndex = item.indexOf('y:');
        if (yearIndex > 0) {
          final title = item.substring(0, yearIndex).trim();
          if (title.isNotEmpty) {
            titles.add(title);
          }
        } else {
          // If no year marker, use the whole item as title
          final trimmed = item.trim();
          if (trimmed.isNotEmpty) {
            titles.add(trimmed);
          }
        }
      }
    }

    return titles;
  }

  /// Formats excluded titles for the AI prompt
  static String formatExcludedTitlesForPrompt(List<String> titles) {
    if (titles.isEmpty) return '';
    return titles.join(', ');
  }

  /// Tracks cache keys for later cleanup
  static Future<void> _trackCacheKey(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_cacheKeysKey) ?? [];
    if (!keys.contains(cacheKey)) {
      keys.add(cacheKey);
      await prefs.setStringList(_cacheKeysKey, keys);
    }
  }

  /// Clears all query caches (call when streaming services change)
  static Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_cacheKeysKey) ?? [];

    // Remove all cached queries
    for (final key in keys) {
      await prefs.remove(key);
    }

    // Clear the keys list
    await prefs.remove(_cacheKeysKey);
  }

  /// Clears cache for a specific query
  static Future<void> clearCache(int type, String requestString) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _generateCacheKey(type, requestString);
    await prefs.remove(cacheKey);

    // Remove from tracked keys
    final keys = prefs.getStringList(_cacheKeysKey) ?? [];
    keys.remove(cacheKey);
    await prefs.setStringList(_cacheKeysKey, keys);
  }
}
