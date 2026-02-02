import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/playlist.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/pages/playlist_detail_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/playlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final HttpService _httpService = HttpService();
  final PlaylistService _playlistService = PlaylistService();

  List<BrowseItem> _popularMovies = [];
  List<BrowseItem> _popularShows = [];
  List<BrowseItem> _topRatedMovies = [];
  List<BrowseItem> _topRatedShows = [];
  List<Playlist> _playlists = [];
  List<int> _userServiceIds = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _playlistService.initialize();

    // Load user's streaming services and all data in parallel
    final results = await Future.wait([
      DatabaseService.getStreamingServicesIds(),
      _httpService.getPopularMovies(),
      _httpService.getPopularShows(),
      _httpService.getTopRatedMovies(),
      _httpService.getTopRatedShows(),
      _playlistService.getPlaylists(),
    ]);

    if (mounted) {
      setState(() {
        _userServiceIds = results[0] as List<int>;
        _popularMovies = results[1] as List<BrowseItem>;
        _popularShows = results[2] as List<BrowseItem>;
        _topRatedMovies = results[3] as List<BrowseItem>;
        _topRatedShows = results[4] as List<BrowseItem>;
        _playlists = results[5] as List<Playlist>;
        _isLoading = false;
      });

      // Load availability in the background
      _loadAvailability();
    }
  }

  Future<void> _loadAvailability() async {
    // Load availability for all items
    final allItems = [
      ..._popularMovies,
      ..._popularShows,
      ..._topRatedMovies,
      ..._topRatedShows,
    ];

    await _httpService.loadBrowseItemsAvailability(allItems);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: Colors.orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Text(
                          'browse'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Popular Movies section
                      if (_popularMovies.isNotEmpty)
                        _buildCarouselSection(
                          title: 'popular_movies'.tr(),
                          items: _popularMovies,
                        ),

                      // Popular Shows section
                      if (_popularShows.isNotEmpty)
                        _buildCarouselSection(
                          title: 'popular_shows'.tr(),
                          items: _popularShows,
                        ),

                      // Curated Playlists section
                      if (_playlists.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text(
                            'curated_playlists'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildPlaylistsSection(),
                      ],

                      // Top Rated Movies section
                      if (_topRatedMovies.isNotEmpty)
                        _buildCarouselSection(
                          title: 'top_rated_movies'.tr(),
                          items: _topRatedMovies,
                        ),

                      // Top Rated Shows section
                      if (_topRatedShows.isNotEmpty)
                        _buildCarouselSection(
                          title: 'top_rated_shows'.tr(),
                          items: _topRatedShows,
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCarouselSection({
    required String title,
    required List<BrowseItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildCarouselItem(items[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(BrowseItem item) {
    final isAvailable = item.availabilityLoaded && item.isAvailableOnStreaming(_userServiceIds);
    final hasRentOrBuy = item.availabilityLoaded && item.hasRentOrBuy;

    return GestureDetector(
      onTap: () => _openItem(item),
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with availability badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w342${item.posterPath}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orange,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.movie, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                  ),
                  // Availability badge
                  if (item.availabilityLoaded)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.withValues(alpha: 0.9)
                              : (hasRentOrBuy
                                  ? Colors.orange.withValues(alpha: 0.9)
                                  : Colors.grey.withValues(alpha: 0.9)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? 'stream'.tr() : (hasRentOrBuy ? 'rent_buy'.tr() : 'N/A'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsSection() {
    final languageCode = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _playlists.map((playlist) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openPlaylist(playlist),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            playlist.icon ?? '🎬',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.getLocalizedTitle(languageCode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${playlist.items.length} ${'titles'.tr()}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openItem(BrowseItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailPage(
          mediaId: item.id,
          title: item.title,
          isMovie: item.isMovie,
          posterPath: item.posterPath,
        ),
      ),
    );
  }

  void _openPlaylist(Playlist playlist) {
    // Track playlist viewed
    UserActionService.logPlaylistViewed(
      playlistId: playlist.id,
      playlistTitle: playlist.title,
      itemsCount: playlist.items.length,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailPage(playlist: playlist),
      ),
    );
  }
}
