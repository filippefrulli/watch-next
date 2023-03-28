class Genre {
  int id;
  String name;

  Genre(
    this.id,
    this.name,
  );
}

List<Genre> genreList = [
  Genre(
    28,
    'action',
  ),
  Genre(
    12,
    'adventure',
  ),
  Genre(
    15,
    'animation',
  ),
  Genre(
    35,
    'comedy',
  ),
  Genre(
    80,
    'crime',
  ),
  Genre(
    99,
    'documentary',
  ),
  Genre(
    18,
    'drama',
  ),
  Genre(
    10751,
    'family',
  ),
  Genre(
    14,
    'fantasy',
  ),
  Genre(
    36,
    'history',
  ),
  Genre(
    27,
    'horror',
  ),
  Genre(
    10402,
    'music',
  ),
  Genre(
    9648,
    'mistery',
  ),
  Genre(
    10749,
    'romance',
  ),
  Genre(
    878,
    'science fiction',
  ),
  Genre(
    53,
    'thriller',
  ),
  Genre(
    10752,
    'war',
  ),
  Genre(
    37,
    'western',
  ),
];

const List<String> streamingServicesLogos = [
  'assets/streaming_services/netflix.png',
  'assets/streaming_services/prime_video.png',
  'assets/streaming_services/apple_tv.png',
  'assets/streaming_services/disney+.png',
  'assets/streaming_services/hbo_max.png',
  'assets/streaming_services/hulu.png',
  'assets/streaming_services/paramount+.png',
  'assets/streaming_services/peacock.png',
];

final Map<int, String> availableCategories = {
  0: 'Lean back and relax',
  1: 'Quality cinema',
  2: 'Action packed',
  3: 'Romantic date',
  4: 'For children',
  5: 'Horror night',
  6: 'Anything',
};
