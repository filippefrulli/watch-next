import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/playlist.dart';
import 'package:watch_next/services/http_service.dart';

class PlaylistService {
  final HttpService _httpService = HttpService();
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static const String _cacheKey = 'cached_playlists';
  static const String _cacheTimestampKey = 'cached_playlists_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  List<Playlist>? _memoryCache;

  /// Initialize Remote Config with defaults
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ));

    // Set default value (empty playlists)
    await _remoteConfig.setDefaults({
      'playlists': '{"playlists": []}',
    });
  }

  /// Check if local cache is still valid (less than 24 hours old)
  Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime) < _cacheDuration;
  }

  /// Get playlists from local cache
  Future<List<Playlist>?> _getFromCache() async {
    // Check memory cache first
    if (_memoryCache != null) {
      return _memoryCache;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson == null) return null;

    try {
      final List<dynamic> playlistsJson = jsonDecode(cachedJson) as List<dynamic>;
      final List<Playlist> playlists = [];
      for (int i = 0; i < playlistsJson.length; i++) {
        final playlist = Playlist.fromJson(playlistsJson[i] as Map<String, dynamic>, index: i);
        if (playlist.active) {
          playlists.add(playlist);
        }
      }
      playlists.sort((a, b) => a.order.compareTo(b.order));
      _memoryCache = playlists;
      return playlists;
    } catch (e) {
      return null;
    }
  }

  /// Save playlists to local cache
  Future<void> _saveToCache(List<Map<String, dynamic>> playlistsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(playlistsJson));
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Fetch playlists from Remote Config and update cache
  Future<List<Playlist>> _fetchFromRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      final jsonString = _remoteConfig.getString('playlists');
      if (jsonString.isEmpty) {
        return [];
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> playlistsJson = data['playlists'] as List<dynamic>? ?? [];

      // Save raw JSON to cache
      await _saveToCache(playlistsJson.cast<Map<String, dynamic>>());

      final List<Playlist> playlists = [];
      for (int i = 0; i < playlistsJson.length; i++) {
        final playlist = Playlist.fromJson(playlistsJson[i] as Map<String, dynamic>, index: i);
        if (playlist.active) {
          playlists.add(playlist);
        }
      }

      playlists.sort((a, b) => a.order.compareTo(b.order));
      _memoryCache = playlists;
      return playlists;
    } catch (e) {
      return [];
    }
  }

  /// Fetch all active playlists (from cache if valid, otherwise from Remote Config)
  Future<List<Playlist>> getPlaylists() async {
    // Check if cache is valid
    if (await _isCacheValid()) {
      final cached = await _getFromCache();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // Cache expired or empty, fetch from Remote Config
    return await _fetchFromRemoteConfig();
  }

  /// Fetch a single playlist by ID
  Future<Playlist?> getPlaylist(String playlistId) async {
    final playlists = await getPlaylists();
    try {
      return playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      return null;
    }
  }

  /// Load full details for playlist items from TMDB
  Future<List<LoadedPlaylistItem>> loadPlaylistItems(Playlist playlist) async {
    final List<LoadedPlaylistItem> loadedItems = [];

    for (final item in playlist.items) {
      try {
        final loadedItem = await _loadItem(item);
        if (loadedItem != null) {
          loadedItems.add(loadedItem);
        }
      } catch (e) {
        // Skip items that fail to load
        continue;
      }
    }

    return loadedItems;
  }

  /// Load a single item with details and availability
  Future<LoadedPlaylistItem?> _loadItem(PlaylistItem item) async {
    try {
      if (item.isMovie) {
        // Fetch movie details
        final details = await _httpService.fetchMovieDetails(item.tmdbId);

        // Fetch availability
        final availability = await _httpService.getCategorizedWatchProviders(
          item.tmdbId,
          true, // isMovie
        );

        return LoadedPlaylistItem(
          tmdbId: item.tmdbId,
          isMovie: true,
          title: details.title ?? 'Unknown',
          posterPath: details.posterPath,
          overview: details.overview,
          voteAverage: details.voteAverage,
          releaseDate: details.releaseDate,
          streamingProviderIds: availability.streaming.map((s) => s.providerId ?? 0).toList(),
          rentProviderIds: availability.rent.map((s) => s.providerId ?? 0).toList(),
          buyProviderIds: availability.buy.map((s) => s.providerId ?? 0).toList(),
        );
      } else {
        // Fetch TV show details
        final details = await _httpService.fetchSeriesDetails(item.tmdbId);

        // Fetch availability
        final availability = await _httpService.getCategorizedWatchProviders(
          item.tmdbId,
          false, // isMovie
        );

        return LoadedPlaylistItem(
          tmdbId: item.tmdbId,
          isMovie: false,
          title: details.name ?? 'Unknown',
          posterPath: details.posterPath,
          overview: details.overview,
          voteAverage: details.voteAverage,
          releaseDate: details.firstAirDate,
          streamingProviderIds: availability.streaming.map((s) => s.providerId ?? 0).toList(),
          rentProviderIds: availability.rent.map((s) => s.providerId ?? 0).toList(),
          buyProviderIds: availability.buy.map((s) => s.providerId ?? 0).toList(),
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Force refresh playlists from Remote Config (clears cache)
  Future<void> refresh() async {
    _memoryCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTimestampKey);
    await _fetchFromRemoteConfig();
  }

  /// Clear all cached playlist data
  Future<void> clearCache() async {
    _memoryCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
