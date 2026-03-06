import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/watched_service.dart';
import 'package:watch_next/objects/streaming_service.dart';
import 'package:watch_next/widgets/watched/rating_dialog.dart';
import 'package:watch_next/objects/movie_details.dart';
import 'package:watch_next/objects/series_details.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/widgets/recommendation_results/trailer_list_widget.dart';
import 'package:watch_next/pages/person_detail_page.dart';
import 'package:watch_next/pages/recommendation_loading_page.dart';

class MediaDetailPage extends StatefulWidget {
  final int mediaId;
  final String title;
  final bool isMovie;
  final String? posterPath;

  const MediaDetailPage({
    super.key,
    required this.mediaId,
    required this.title,
    required this.isMovie,
    this.posterPath,
  });

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> with SingleTickerProviderStateMixin {
  final WatchlistService _watchlistService = WatchlistService();
  final WatchedService _watchedService = WatchedService();

  // Availability state
  bool _isLoading = true;
  bool _isInWatchlist = false;
  bool _isWatched = false;
  int? _watchedRating;
  List<StreamingService> _streamingProviders = [];
  List<StreamingService> _rentProviders = [];
  List<StreamingService> _buyProviders = [];
  List<int> _userServiceIds = [];
  String _errorMessage = '';

  // Details state
  bool _isDetailsLoading = true;
  bool _isGenerating = false;
  MovieDetails? _movieDetails;
  SeriesDetails? _seriesDetails;
  MovieCredits? _credits;
  List<BrowseItem> _similarItems = [];

  // Trailer state
  List<TrailerResults> _trailerList = [];
  List<String> _trailerImages = [];
  final String _trailerBaseUrl = 'https://www.youtube.com/watch?v=';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _userServiceIds = await DatabaseService.getStreamingServicesIds();
      final inWatchlist = await _watchlistService.isInWatchlist(widget.mediaId);
      final watchedItem = await _watchedService.getWatchedItem(widget.mediaId);
      final categorizedProviders = await HttpService().getCategorizedWatchProviders(
        widget.mediaId,
        widget.isMovie,
      );

      setState(() {
        _isInWatchlist = inWatchlist;
        _isWatched = watchedItem != null;
        _watchedRating = watchedItem?.rating;
        _streamingProviders = categorizedProviders.streaming;
        _rentProviders = categorizedProviders.rent;
        _buyProviders = categorizedProviders.buy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'failed_load_streaming'.tr();
      });
    }
  }

  Future<void> _loadDetails() async {
    try {
      if (widget.isMovie) {
        final detailsFuture = HttpService().fetchMovieDetails(widget.mediaId);
        final creditsFuture = HttpService().fetchMovieCredits(widget.mediaId);
        final trailerFuture = HttpService().fetchTrailer(widget.mediaId);
        final similarFuture = HttpService().fetchSimilar(widget.mediaId, isMovie: true);
        final details = await detailsFuture;
        final credits = await creditsFuture;
        final trailers = await trailerFuture;
        final similar = await similarFuture;
        if (mounted) {
          setState(() {
            _movieDetails = details;
            _credits = credits;
            _trailerList = trailers;
            _similarItems = similar;
            _isDetailsLoading = false;
          });
        }
      } else {
        final detailsFuture = HttpService().fetchSeriesDetails(widget.mediaId);
        final creditsFuture = HttpService().fetchSeriesCredits(widget.mediaId);
        final trailerFuture = HttpService().fetchTrailerSeries(widget.mediaId);
        final similarFuture = HttpService().fetchSimilar(widget.mediaId, isMovie: false);
        final details = await detailsFuture;
        final credits = await creditsFuture;
        final trailers = await trailerFuture;
        final similar = await similarFuture;
        if (mounted) {
          setState(() {
            _seriesDetails = details;
            _credits = credits;
            _trailerList = trailers;
            _similarItems = similar;
            _isDetailsLoading = false;
          });
        }
      }
      // Load thumbnail images for trailers
      await _loadTrailerImages();
    } catch (e) {
      if (mounted) {
        setState(() => _isDetailsLoading = false);
      }
    }
  }

  Future<void> _loadTrailerImages() async {
    final images = <String>[];
    for (final trailer in _trailerList) {
      final jsonData = await HttpService().getDetail(_trailerBaseUrl + (trailer.key ?? ''));
      if (jsonData != null) {
        images.add(jsonData['thumbnail_url'] as String);
      } else {
        images.add('https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg');
      }
    }
    if (mounted) {
      setState(() => _trailerImages = images);
    }
  }

  Future<void> _launchTrailerURL(String key) async {
    final uri = Uri.parse(_trailerBaseUrl + key);
    if (Platform.isIOS) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isInWatchlist) {
        await _watchlistService.removeFromWatchlist(widget.mediaId);
        if (mounted) setState(() => _isInWatchlist = false);
        UserActionService.logWatchlistRemove(
          mediaId: widget.mediaId,
          title: widget.title,
          type: widget.isMovie ? 'movie' : 'show',
        );
      } else {
        await _watchlistService.addToWatchlist(
          mediaId: widget.mediaId,
          title: widget.title,
          isMovie: widget.isMovie,
          posterPath: widget.posterPath,
        );
        if (mounted) {
          setState(() => _isInWatchlist = true);
        }
        UserActionService.logWatchlistAdd(
          mediaId: widget.mediaId,
          title: widget.title,
          type: widget.isMovie ? 'movie' : 'show',
          source: 'media_detail',
        );
      }
    } catch (e) {
      // Handle errors if necessary
    }
  }

  Future<void> _toggleWatched() async {
    if (_isWatched) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('remove_from_watched'.tr(), style: const TextStyle(color: Colors.white)),
          content: Text(widget.title, style: TextStyle(color: Colors.grey[400])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('remove'.tr(), style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _watchedService.removeFromWatched(widget.mediaId);
      if (mounted)
        setState(() {
          _isWatched = false;
          _watchedRating = null;
        });
      UserActionService.logWatchedRemove(
        mediaId: widget.mediaId,
        title: widget.title,
        type: widget.isMovie ? 'movie' : 'show',
      );
    } else {
      final result = await _showRatingDialog();
      if (result == null) return;
      await _watchedService.markAsWatched(WatchedItem(
        mediaId: widget.mediaId,
        title: widget.title,
        isMovie: widget.isMovie,
        posterPath: widget.posterPath,
        rating: result.rating,
        dateWatched: result.dateWatched,
        overview: _movieDetails?.overview ?? _seriesDetails?.overview,
        genreNames: [
          ...?_movieDetails?.genres?.map((g) => g.name ?? '').where((n) => n.isNotEmpty),
          ...?_seriesDetails?.genres?.map((g) => g.name ?? '').where((n) => n.isNotEmpty),
        ],
      ));
      if (mounted)
        setState(() {
          _isWatched = true;
          _watchedRating = result.rating;
        });
      UserActionService.logWatchedAdd(
        mediaId: widget.mediaId,
        title: widget.title,
        type: widget.isMovie ? 'movie' : 'show',
        rating: result.rating,
        source: 'media_detail',
      );
    }
  }

  Future<RatingResult?> _showRatingDialog() {
    return RatingDialog.show(context, title: widget.title);
  }

  Future<void> _generateSimilar() async {
    setState(() => _isGenerating = true);
    UserActionService.logButtonPressed(
      buttonName: widget.isMovie ? 'suggest_similar_movies' : 'suggest_similar_shows',
    );
    final typeLabel = widget.isMovie ? 'Movies' : 'TV shows';
    final requestString = '$typeLabel similar to ${widget.title}';
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecommendationLoadingPage(
          requestString: requestString,
          type: widget.isMovie ? 0 : 1,
          itemsToNotRecommend: widget.title,
        ),
      ),
    );
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _isDetailsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              'loading'.tr(),
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Poster height + watchlist button area that will collapse
    const double expandedHeight = 490;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          pinned: true,
          floating: false,
          expandedHeight: expandedHeight,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: _buildPosterAndWatchlist(),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.orange,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey[500],
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'availability'.tr()),
                  Tab(text: 'details'.tr()),
                ],
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailabilityTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  // ── POSTER + WATCHLIST ──────────────────────────────────────────────────

  Widget _buildPosterAndWatchlist() {
    return Column(
      children: [
        _buildPoster(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildWatchlistButton(),
        ),
      ],
    );
  }

  Widget _buildPoster() {
    if (widget.posterPath == null) {
      return Container(
        width: 220,
        height: 330,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 60),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: 'https://image.tmdb.org/t/p/w500${widget.posterPath}',
        width: 220,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: 220,
          height: 330,
          color: Theme.of(context).colorScheme.tertiary,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 220,
          height: 330,
          color: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
        ),
      ),
    );
  }

  // ── WATCHLIST + WATCHED BUTTONS ─────────────────────────────────────────

  Widget _buildWatchlistButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Watchlist
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleWatchlist,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color:
                      _isInWatchlist ? Colors.orange.withValues(alpha: 0.15) : Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isInWatchlist ? Colors.orange : Theme.of(context).colorScheme.outline,
                    width: _isInWatchlist ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                      color: _isInWatchlist ? Colors.orange : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _isInWatchlist ? 'remove_from_watchlist'.tr() : 'add_to_watchlist'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isInWatchlist ? Colors.orange : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Watched
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleWatched,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _isWatched ? Colors.green.withValues(alpha: 0.15) : Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isWatched ? Colors.green : Theme.of(context).colorScheme.outline,
                    width: _isWatched ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isWatched ? Icons.check_circle : Icons.check_circle_outline,
                      color: _isWatched ? Colors.green : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _isWatched ? '${'watched_rating'.tr()} $_watchedRating/10' : 'mark_watched'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isWatched ? Colors.green : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── DETAILS TAB ──────────────────────────────────────────────────────────

  Widget _buildDetailsTab() {
    if (_isDetailsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              widget.isMovie ? _buildMovieDetails() : _buildSeriesDetails(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMovieDetails() {
    final movie = _movieDetails;
    if (movie == null) return const SizedBox.shrink();

    final directors = _credits?.crew?.where((c) => c.job == 'Director').toList() ?? [];

    final topCast = _credits?.cast?.take(15).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta row: year · runtime · rating
        _buildMetaRow([
          if (movie.releaseDate != null && movie.releaseDate!.length >= 4) movie.releaseDate!.substring(0, 4),
          if (movie.runtime != null && movie.runtime! > 0) '${movie.runtime} min',
          if (movie.voteAverage != null && movie.voteAverage! > 0) '⭐ ${movie.voteAverage!.toStringAsFixed(1)}',
        ]),
        const SizedBox(height: 16),
        // Genres
        if (movie.genres != null && movie.genres!.isNotEmpty) ...[
          _buildGenreChips(movie.genres!.map((g) => g.name ?? '').toList()),
          const SizedBox(height: 20),
        ],
        // Overview
        if (movie.overview != null && movie.overview!.isNotEmpty) ...[
          _buildSectionLabel('overview'.tr()),
          const SizedBox(height: 8),
          Text(
            movie.overview!,
            style: TextStyle(color: Colors.grey[300], fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 20),
        ],
        // Director(s)
        if (directors.isNotEmpty) ...[
          _buildSectionLabel('director'.tr()),
          const SizedBox(height: 12),
          _buildDirectorRow(directors),
          const SizedBox(height: 20),
        ],
        // Cast
        if (topCast.isNotEmpty) ...[
          _buildSectionLabel('cast'.tr()),
          const SizedBox(height: 12),
          _buildCastRow(topCast),
          const SizedBox(height: 20),
        ],
        // Trailers
        TrailerListWidget(
          trailerList: _trailerList,
          trailerImages: _trailerImages,
          onTrailerTap: _launchTrailerURL,
        ),
        // Generate similar button
        const SizedBox(height: 24),
        _buildGenerateSimilarButton(),
        // Similar titles
        if (_similarItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionLabel('similar_titles'.tr()),
          const SizedBox(height: 12),
          _buildSimilarCarousel(),
        ],
      ],
    );
  }

  Widget _buildSeriesDetails() {
    final series = _seriesDetails;
    if (series == null) return const SizedBox.shrink();

    final topCast = _credits?.cast?.take(15).toList() ?? [];
    final creators = _credits?.crew
        ?.where((c) => c.job == 'Executive Producer' || c.job == 'Creator')
        .take(2)
        .map((c) => c.name ?? '')
        .join(', ');

    final episodeRuntime =
        series.episodeRunTime != null && series.episodeRunTime!.isNotEmpty ? series.episodeRunTime!.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta row: year · seasons · episodes · rating
        _buildMetaRow([
          if (series.firstAirDate != null && series.firstAirDate!.length >= 4) series.firstAirDate!.substring(0, 4),
          if (series.numberOfSeasons != null) '${series.numberOfSeasons} ${'seasons'.tr()}',
          if (series.numberOfEpisodes != null) '${series.numberOfEpisodes} ep.',
          if (series.voteAverage != null && series.voteAverage! > 0) '⭐ ${series.voteAverage!.toStringAsFixed(1)}',
        ]),
        const SizedBox(height: 16),
        // Genres
        if (series.genres != null && series.genres!.isNotEmpty) ...[
          _buildGenreChips(series.genres!.map((g) => g.name ?? '').toList()),
          const SizedBox(height: 20),
        ],
        // Overview
        if (series.overview != null && series.overview!.isNotEmpty) ...[
          _buildSectionLabel('overview'.tr()),
          const SizedBox(height: 8),
          Text(
            series.overview!,
            style: TextStyle(color: Colors.grey[300], fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 20),
        ],
        // Episode runtime
        if (episodeRuntime != null && episodeRuntime > 0) ...[
          _buildDetailRow(Icons.timer_outlined, 'episode_runtime'.tr(), '$episodeRuntime min'),
          const SizedBox(height: 12),
        ],
        // Status
        if (series.status != null && series.status!.isNotEmpty) ...[
          _buildDetailRow(
            series.inProduction == true ? Icons.fiber_manual_record : Icons.check_circle_outline,
            'status'.tr(),
            series.status!,
            iconColor: series.inProduction == true ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 20),
        ],
        // Creator/Executive Producer
        if (creators != null && creators.isNotEmpty) ...[
          _buildDetailRow(Icons.movie_creation_outlined, 'created_by'.tr(), creators),
          const SizedBox(height: 20),
        ],
        // Cast
        if (topCast.isNotEmpty) ...[
          _buildSectionLabel('cast'.tr()),
          const SizedBox(height: 12),
          _buildCastRow(topCast),
          const SizedBox(height: 20),
        ],
        // Trailers
        TrailerListWidget(
          trailerList: _trailerList,
          trailerImages: _trailerImages,
          onTrailerTap: _launchTrailerURL,
        ),
        // Generate similar button
        const SizedBox(height: 24),
        _buildGenerateSimilarButton(),
        // Similar titles
        if (_similarItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionLabel('similar_titles'.tr()),
          const SizedBox(height: 12),
          _buildSimilarCarousel(),
        ],
      ],
    );
  }

  Widget _buildGenerateSimilarButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isGenerating ? null : _generateSimilar,
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
              )
            : const Icon(Icons.auto_awesome, size: 18, color: Colors.orange),
        label: Text(
          widget.isMovie ? 'suggest_similar_movies'.tr() : 'suggest_similar_shows'.tr(),
          style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: const BorderSide(color: Colors.orange, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSimilarCarousel() {
    return SizedBox(
      height: 215,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _similarItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _similarItems[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaDetailPage(
                  mediaId: item.id,
                  title: item.title,
                  isMovie: item.isMovie,
                  posterPath: item.posterPath,
                ),
              ),
            ),
            child: SizedBox(
              width: 126,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w185${item.posterPath}',
                            width: 126,
                            height: 188,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 126,
                              height: 188,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 126,
                              height: 188,
                              color: Theme.of(context).colorScheme.tertiary,
                              child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 28),
                            ),
                          )
                        : Container(
                            width: 126,
                            height: 188,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.movie_outlined, color: Colors.grey[600], size: 28),
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Text(
                  item,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGenreChips(List<String> genres) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: genres
          .map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  g,
                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? Colors.orange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCastRow(List<Cast> cast) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final actor = cast[index];
          return GestureDetector(
            onTap: actor.id != null
                ? () {
                    UserActionService.logPersonTapped(
                      personId: actor.id!,
                      personName: actor.name ?? '',
                      role: 'cast',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailPage(
                          personId: actor.id!,
                          personName: actor.name ?? '',
                          profilePath: actor.profilePath,
                        ),
                      ),
                    );
                  }
                : null,
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: actor.profilePath != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w185${actor.profilePath}',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _actorPlaceholder(),
                          )
                        : _actorPlaceholder(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actor.name ?? '',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDirectorRow(List<Crew> directors) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: directors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final director = directors[index];
          return GestureDetector(
            onTap: director.id != null
                ? () {
                    UserActionService.logPersonTapped(
                      personId: director.id!,
                      personName: director.name ?? '',
                      role: 'director',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailPage(
                          personId: director.id!,
                          personName: director.name ?? '',
                          profilePath: director.profilePath,
                        ),
                      ),
                    );
                  }
                : null,
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: director.profilePath != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w185${director.profilePath}',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _actorPlaceholder(),
                          )
                        : _actorPlaceholder(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    director.name ?? '',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actorPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Theme.of(context).colorScheme.tertiary,
      child: Icon(Icons.person, color: Colors.grey[600], size: 32),
    );
  }

  // ── AVAILABILITY TAB ─────────────────────────────────────────────────────

  Widget _buildAvailabilityTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStreamingProvidersSection(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingProvidersSection() {
    final hasAnyContent = _streamingProviders.isNotEmpty || _rentProviders.isNotEmpty || _buyProviders.isNotEmpty;

    if (!hasAnyContent) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[400], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'not_available_region'.tr(),
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_streamingProviders.isNotEmpty) ...[
          _buildSectionHeader('stream'.tr(), Icons.play_circle_outline, Colors.green),
          const SizedBox(height: 12),
          ..._streamingProviders.map((p) => _buildProviderCard(p, _userServiceIds.contains(p.providerId))),
          const SizedBox(height: 24),
        ],
        if (_rentProviders.isNotEmpty) ...[
          _buildSectionHeader('rent'.tr(), Icons.schedule, Colors.orange),
          const SizedBox(height: 12),
          ..._rentProviders.map((p) => _buildProviderCard(p, false, showCheckmark: false)),
          const SizedBox(height: 24),
        ],
        if (_buyProviders.isNotEmpty) ...[
          _buildSectionHeader('buy'.tr(), Icons.shopping_cart_outlined, Colors.blue),
          const SizedBox(height: 12),
          ..._buyProviders.map((p) => _buildProviderCard(p, false, showCheckmark: false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildProviderCard(StreamingService provider, bool isSubscribed, {bool showCheckmark = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed ? Colors.green : Theme.of(context).colorScheme.outline,
          width: isSubscribed ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: provider.logoPath != null
                ? CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/original${provider.logoPath}',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).colorScheme.tertiary,
                      child: Icon(Icons.tv, color: Colors.grey[600], size: 24),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Theme.of(context).colorScheme.tertiary,
                    child: Icon(Icons.tv, color: Colors.grey[600], size: 24),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              provider.providerName ?? 'unknown'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (showCheckmark && isSubscribed)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
}
