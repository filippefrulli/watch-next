class Playlist {
  final String id;
  final String title;
  final Map<String, String>? titles; // Localized titles
  final String? description;
  final Map<String, String>? descriptions; // Localized descriptions
  final String? icon;
  final int order;
  final bool active;
  final List<PlaylistItem> items;

  Playlist({
    required this.id,
    required this.title,
    this.titles,
    this.description,
    this.descriptions,
    this.icon,
    this.order = 0,
    this.active = true,
    required this.items,
  });

  /// Get localized title based on language code (e.g., "en", "de", "es")
  String getLocalizedTitle(String languageCode) {
    if (titles != null && titles!.containsKey(languageCode)) {
      return titles![languageCode]!;
    }
    return title; // Fallback to default title
  }

  /// Get localized description based on language code
  String? getLocalizedDescription(String languageCode) {
    if (descriptions != null && descriptions!.containsKey(languageCode)) {
      return descriptions![languageCode];
    }
    return description; // Fallback to default description
  }

  factory Playlist.fromJson(Map<String, dynamic> json, {int index = 0}) {
    // Parse items - can be either simple TMDB IDs or full item objects
    final itemsData = json['items'] as List<dynamic>? ?? [];
    final List<PlaylistItem> parsedItems = [];

    // Determine if this is a TV show playlist based on ID or title
    final id = json['id'] as String? ?? '';
    final title = json['title'] as String? ?? '';
    final isTvShowPlaylist =
        id.contains('show') || title.toLowerCase().contains('show') || title.toLowerCase().contains('binge');

    for (var item in itemsData) {
      if (item is int) {
        // Simple TMDB ID - use playlist context to determine type
        parsedItems.add(PlaylistItem(tmdbId: item, isMovie: !isTvShowPlaylist));
      } else if (item is Map<String, dynamic>) {
        // Full item object
        parsedItems.add(PlaylistItem.fromMap(item));
      }
    }

    // Parse localized titles
    Map<String, String>? titles;
    if (json['titles'] != null) {
      titles = Map<String, String>.from(json['titles'] as Map);
    }

    // Parse localized descriptions
    Map<String, String>? descriptions;
    if (json['descriptions'] != null) {
      descriptions = Map<String, String>.from(json['descriptions'] as Map);
    }

    return Playlist(
      id: json['id'] as String? ?? 'playlist_$index',
      title: json['title'] as String? ?? 'Untitled',
      titles: titles,
      description: json['description'] as String?,
      descriptions: descriptions,
      icon: json['icon'] as String?,
      order: json['order'] as int? ?? index,
      active: json['active'] as bool? ?? true,
      items: parsedItems,
    );
  }
}

class PlaylistItem {
  final int tmdbId;
  final bool isMovie;

  PlaylistItem({
    required this.tmdbId,
    this.isMovie = true,
  });

  factory PlaylistItem.fromMap(Map<String, dynamic> map) {
    return PlaylistItem(
      tmdbId: map['tmdbId'] as int,
      isMovie: map['isMovie'] as bool? ?? true,
    );
  }
}

/// Loaded playlist item with full details from TMDB
class LoadedPlaylistItem {
  final int tmdbId;
  final bool isMovie;
  final String title;
  final String? posterPath;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final List<int> streamingProviderIds;
  final List<int> rentProviderIds;
  final List<int> buyProviderIds;

  LoadedPlaylistItem({
    required this.tmdbId,
    required this.isMovie,
    required this.title,
    this.posterPath,
    this.overview,
    this.voteAverage,
    this.releaseDate,
    this.streamingProviderIds = const [],
    this.rentProviderIds = const [],
    this.buyProviderIds = const [],
  });

  /// Check if available on user's streaming services
  bool isAvailableOnStreaming(List<int> userServiceIds) {
    return streamingProviderIds.any((id) => userServiceIds.contains(id));
  }

  /// Check if available at all (streaming, rent, or buy)
  bool hasAnyAvailability() {
    return streamingProviderIds.isNotEmpty || rentProviderIds.isNotEmpty || buyProviderIds.isNotEmpty;
  }
}
