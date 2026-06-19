/// Builds a "watch now" URL that lands on the streaming provider itself.
///
/// TMDB's watch-providers API only returns a single TMDB/JustWatch attribution
/// page, never per-service links, so we construct a search-by-title URL on each
/// major provider's own site. Any provider we don't have a mapping for falls
/// back to a region-aware JustWatch search, which covers every service.
class StreamingLinkService {
  static Uri searchUrl({
    String? providerName,
    required String title,
    required String region,
  }) {
    final q = Uri.encodeQueryComponent(title);
    final name = (providerName ?? '').toLowerCase();

    String? url;
    if (name.contains('netflix')) {
      url = 'https://www.netflix.com/search?q=$q';
    } else if (name.contains('disney')) {
      url = 'https://www.disneyplus.com/search?q=$q';
    } else if (name.contains('apple')) {
      url = 'https://tv.apple.com/search?term=$q';
    } else if (name.contains('prime video') || name.contains('amazon')) {
      url = 'https://www.amazon.com/s?k=$q&i=instant-video';
    } else if (name.contains('hbo') || name == 'max') {
      url = 'https://play.max.com/search?q=$q';
    } else if (name.contains('hulu')) {
      url = 'https://www.hulu.com/search?q=$q';
    } else if (name.contains('paramount')) {
      url = 'https://www.paramountplus.com/search/?query=$q';
    } else if (name.contains('peacock')) {
      url = 'https://www.peacocktv.com/search?q=$q';
    } else if (name.contains('crunchyroll')) {
      url = 'https://www.crunchyroll.com/search?q=$q';
    } else if (name.contains('youtube')) {
      url = 'https://www.youtube.com/results?search_query=$q';
    } else if (name.contains('google play')) {
      url = 'https://play.google.com/store/search?q=$q&c=movies';
    } else if (name.contains('mubi')) {
      url = 'https://mubi.com/search/films?query=$q';
    }

    // Fallback: region-aware JustWatch search (covers every provider).
    url ??= 'https://www.justwatch.com/${_justWatchRegion(region)}/search?q=$q';
    return Uri.parse(url);
  }

  static String _justWatchRegion(String region) {
    final r = region.toLowerCase();
    // JustWatch uses /uk for the United Kingdom.
    return r == 'gb' ? 'uk' : r;
  }
}
