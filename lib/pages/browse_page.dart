import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/widgets/shared/native_ad_widget.dart';
import 'package:watch_next/objects/playlist.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/pages/playlist_detail_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/services/playlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/utils/app_colors.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final HttpService _httpService = HttpService();
  final PlaylistService _playlistService = PlaylistService();

  // Priority-ordered list of well-known provider IDs
  static const _providerPriority = [8, 9, 337, 350, 1899, 15, 531, 386, 283];
  static const _providerNames = {
    8: 'Netflix',
    9: 'Prime Video',
    337: 'Disney+',
    350: 'Apple TV+',
    1899: 'Max',
    15: 'Hulu',
    531: 'Paramount+',
    386: 'Peacock',
    283: 'Crunchyroll',
  };

  List<BrowseItem> _popularMovies = [];
  List<BrowseItem> _popularShows = [];
  List<BrowseItem> _topRatedMovies = [];
  List<BrowseItem> _topRatedShows = [];
  List<BrowseItem> _trending = [];
  List<BrowseItem> _nowPlaying = [];
  List<BrowseItem> _upcoming = [];
  List<BrowseItem> _hiddenGems = [];
  // provider id → items
  Map<int, List<BrowseItem>> _providerCarousels = {};
  List<int> _prioritisedUserServices = [];

  List<Playlist> _playlists = [];
  List<int> _userServiceIds = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _playlistService.initialize().timeout(const Duration(seconds: 10));

      final results = await Future.wait([
        DatabaseService.getStreamingServicesIds(),
        _httpService.getPopularMovies(),
        _httpService.getPopularShows(),
        _httpService.getTopRatedMovies(),
        _httpService.getTopRatedShows(),
        _httpService.getTrending(mediaType: 'all', timeWindow: 'week'),
        _httpService.getNowPlayingMovies(),
        _httpService.getUpcomingMovies(),
        _playlistService.getPlaylists(),
      ]).timeout(const Duration(seconds: 25));

      if (mounted) {
        final userIds = results[0] as List<int>;
        // Pick up to 5 subscribed services in priority order
        final prioritised = _providerPriority
            .where((id) => userIds.contains(id))
            .take(5)
            .toList();

        setState(() {
          _userServiceIds = userIds;
          _prioritisedUserServices = prioritised;
          _popularMovies = results[1] as List<BrowseItem>;
          _popularShows = results[2] as List<BrowseItem>;
          _topRatedMovies = results[3] as List<BrowseItem>;
          _topRatedShows = results[4] as List<BrowseItem>;
          _trending = results[5] as List<BrowseItem>;
          _nowPlaying = results[6] as List<BrowseItem>;
          _upcoming = results[7] as List<BrowseItem>;
          _playlists = results[8] as List<Playlist>;
          _isLoading = false;
        });

        _loadSecondaryData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading Discover: $e';
        });
      }
    }
  }

  Future<void> _loadSecondaryData() async {
    // Load provider carousels and hidden gems in background
    final futures = <Future>[];

    for (final providerId in _prioritisedUserServices) {
      futures.add(_httpService.getNewOnProvider(providerId).then((items) {
        if (mounted) {
          setState(() => _providerCarousels[providerId] = items);
        }
      }));
    }

    futures.add(_httpService.getHiddenGems().then((items) {
      if (mounted) setState(() => _hiddenGems = items);
    }));

    await Future.wait(futures);

    // Load availability for all items
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final allItems = [
      ..._popularMovies,
      ..._popularShows,
      ..._topRatedMovies,
      ..._topRatedShows,
      ..._trending,
      ..._nowPlaying,
      ..._hiddenGems,
      ..._providerCarousels.values.expand((l) => l),
    ];

    await _httpService.loadBrowseItemsAvailability(allItems);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          SelectableText(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _errorMessage = '');
                              _loadData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.accent,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'browse'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                                  ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trending This Week
                          if (_trending.isNotEmpty)
                            _buildCarouselSection(
                              title: 'trending_this_week'.tr(),
                              items: _trending,
                            ),

                          // Now in Cinemas
                          if (_nowPlaying.isNotEmpty)
                            _buildCarouselSection(
                              title: 'now_in_cinemas'.tr(),
                              items: _nowPlaying,
                            ),

                          // Coming Soon
                          if (_upcoming.isNotEmpty)
                            _buildCarouselSection(
                              title: 'coming_soon'.tr(),
                              items: _upcoming,
                            ),

                          // New on [Service] — one carousel per subscribed priority service
                          for (final providerId in _prioritisedUserServices)
                            if (_providerCarousels.containsKey(providerId) &&
                                _providerCarousels[providerId]!.isNotEmpty)
                              _buildCarouselSection(
                                title: '${'new_on'.tr()} ${_providerNames[providerId] ?? ''}',
                                items: _providerCarousels[providerId]!,
                              ),

                          // Popular Movies
                          if (_popularMovies.isNotEmpty)
                            _buildCarouselSection(
                              title: 'popular_movies'.tr(),
                              items: _popularMovies,
                            ),

                          // Popular Shows
                          if (_popularShows.isNotEmpty)
                            _buildCarouselSection(
                              title: 'popular_shows'.tr(),
                              items: _popularShows,
                            ),

                          // Curated Playlists
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

                          const NativeAdWidget(),

                          // Hidden Gems
                          if (_hiddenGems.isNotEmpty)
                            _buildCarouselSection(
                              title: 'hidden_gems'.tr(),
                              items: _hiddenGems,
                            ),

                          // Top Rated Movies
                          if (_topRatedMovies.isNotEmpty)
                            _buildCarouselSection(
                              title: 'top_rated_movies'.tr(),
                              items: _topRatedMovies,
                            ),

                          // Top Rated Shows
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
          height: 258,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildCarouselItem(items[index]),
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
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 210,
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
                              color: context.appColors.surface,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: context.appColors.accent,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: context.appColors.surface,
                              child: const Icon(Icons.movie, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: context.appColors.surface,
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                  ),
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
                                  ? Colors.amber[600]!.withValues(alpha: 0.9)
                                  : Colors.grey.withValues(alpha: 0.9)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? 'stream'.tr() : (hasRentOrBuy ? 'rent_buy'.tr() : 'N/A'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[600]),
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
