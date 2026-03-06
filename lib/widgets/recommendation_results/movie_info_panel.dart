import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/movie_details.dart';
import 'package:watch_next/objects/season_episodes.dart';
import 'package:watch_next/objects/series_details.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/pages/person_detail_page.dart';
import 'package:watch_next/pages/media_detail_page.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/watched_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/widgets/recommendation_results/trailer_list_widget.dart';
import 'package:watch_next/widgets/watched/rating_dialog.dart';

class MovieInfoPanel extends StatefulWidget {
  final int mediaId;
  final String title;
  final String overview;
  final double? tmdbRating;
  final bool isMovie;
  final String? posterPath;
  final List<TrailerResults> trailerList;
  final List<String> trailerImages;
  final Function(String) onTrailerTap;

  const MovieInfoPanel({
    super.key,
    required this.mediaId,
    required this.title,
    required this.overview,
    required this.tmdbRating,
    required this.isMovie,
    this.posterPath,
    required this.trailerList,
    required this.trailerImages,
    required this.onTrailerTap,
  });

  @override
  State<MovieInfoPanel> createState() => _MovieInfoPanelState();
}

class _MovieInfoPanelState extends State<MovieInfoPanel> {
  final WatchlistService _watchlistService = WatchlistService();
  final WatchedService _watchedService = WatchedService();
  bool _isInWatchlist = false;
  bool _isWatched = false;
  int? _watchedRating;

  // Extra details loaded lazily
  MovieCredits? _credits;
  MovieDetails? _movieDetails;
  SeriesDetails? _seriesDetails;
  bool _detailsLoaded = false;

  // Season episode cache: seasonNumber → episodes
  final Map<int, List<Episode>> _episodeCache = {};
  final Set<int> _loadingSeasons = {};
  final Set<int> _expandedSeasons = {};

  // Similar titles
  List<BrowseItem> _similarItems = [];

  @override
  void initState() {
    super.initState();
    _checkIfInWatchlist();
    _checkIfWatched();
    _loadDetails();
  }

  @override
  void didUpdateWidget(MovieInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _checkIfInWatchlist();
      _checkIfWatched();
      _detailsLoaded = false;
      _credits = null;
      _movieDetails = null;
      _seriesDetails = null;
      _similarItems = [];
      _episodeCache.clear();
      _loadingSeasons.clear();
      _expandedSeasons.clear();
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    try {
      if (widget.isMovie) {
        final results = await Future.wait([
          HttpService().fetchMovieCredits(widget.mediaId),
          HttpService().fetchMovieDetails(widget.mediaId),
          HttpService().fetchSimilar(widget.mediaId, isMovie: true),
        ]);
        if (mounted) {
          setState(() {
            _credits = results[0] as MovieCredits;
            _movieDetails = results[1] as MovieDetails;
            _similarItems = results[2] as List<BrowseItem>;
            _detailsLoaded = true;
          });
        }
      } else {
        final results = await Future.wait([
          HttpService().fetchSeriesCredits(widget.mediaId),
          HttpService().fetchSeriesDetails(widget.mediaId),
          HttpService().fetchSimilar(widget.mediaId, isMovie: false),
        ]);
        if (mounted) {
          setState(() {
            _credits = results[0] as MovieCredits;
            _seriesDetails = results[1] as SeriesDetails;
            _similarItems = results[2] as List<BrowseItem>;
            _detailsLoaded = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _detailsLoaded = true);
    }
  }

  Future<void> _checkIfInWatchlist() async {
    final inWatchlist = await _watchlistService.isInWatchlist(widget.mediaId);
    if (mounted) {
      setState(() {
        _isInWatchlist = inWatchlist;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isInWatchlist) {
        await _watchlistService.removeFromWatchlist(widget.mediaId);
        if (mounted) {
          setState(() => _isInWatchlist = false);
        }
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
          source: 'recommendation_info',
        );
      }
    } catch (e) {
      // Handle errors if necessary
    }
  }

  Future<void> _checkIfWatched() async {
    final item = await _watchedService.getWatchedItem(widget.mediaId);
    if (mounted) {
      setState(() {
        _isWatched = item != null;
        _watchedRating = item?.rating;
      });
    }
  }

  Future<void> _toggleWatched() async {
    if (_isWatched) {
      // Already watched — offer to remove
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
      final result = await RatingDialog.show(context, title: widget.title);
      if (result == null) return;
      await _watchedService.markAsWatched(WatchedItem(
        mediaId: widget.mediaId,
        title: widget.title,
        isMovie: widget.isMovie,
        posterPath: widget.posterPath,
        rating: result.rating,
        dateWatched: result.dateWatched,
        overview: widget.overview,
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
        source: 'recommendation_info',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DelayedDisplay(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Watchlist + Watched buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Watchlist button
                          Flexible(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _toggleWatchlist,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isInWatchlist
                                        ? Colors.orange.withValues(alpha: 0.2)
                                        : Theme.of(context).colorScheme.tertiary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isInWatchlist ? Colors.orange : Colors.grey[700]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                                        color: _isInWatchlist ? Colors.orange : Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _isInWatchlist ? 'remove_from_watchlist'.tr() : 'add_to_watchlist'.tr(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                                fontSize: 13,
                                                color: _isInWatchlist ? Colors.orange : Colors.white,
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
                          // Watched button
                          Flexible(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _toggleWatched,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isWatched
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Theme.of(context).colorScheme.tertiary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isWatched ? Colors.green : Colors.grey[700]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isWatched ? Icons.check_circle : Icons.check_circle_outline,
                                        color: _isWatched ? Colors.green : Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _isWatched
                                              ? '${"watched_rating".tr()} $_watchedRating/10'
                                              : 'mark_watched'.tr(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                                fontSize: 13,
                                                color: _isWatched ? Colors.green : Colors.white,
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
                      ),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 16),
                      // TMDB score
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'tmdb_score'.tr(),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.tmdbRating?.toStringAsFixed(1) ?? '',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 16),
                      // Overview
                      Text(
                        widget.overview,
                        maxLines: 17,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 16),
                      // Credits / season details
                      if (!_detailsLoaded)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else ...[
                        if (widget.isMovie) _buildMovieCredits() else _buildSeriesSeasons(),
                      ],
                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 8),
                      TrailerListWidget(
                        trailerList: widget.trailerList,
                        trailerImages: widget.trailerImages,
                        onTrailerTap: widget.onTrailerTap,
                      ),
                      if (_similarItems.isNotEmpty) ...[
                        _buildDivider(),
                        const SizedBox(height: 16),
                        _buildSimilarCarousel(),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('similar_titles'.tr()),
        const SizedBox(height: 12),
        SizedBox(
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similarItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = _similarItems[i];
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
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.orange.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  // ── MOVIE: genres + runtime + director + cast ─────────────────────────

  Widget _buildMovieCredits() {
    final directors = _credits?.crew?.where((c) => c.job == 'Director').toList() ?? [];
    final topCast = _credits?.cast?.take(15).toList() ?? [];
    final genres = _movieDetails?.genres ?? [];
    final runtime = _movieDetails?.runtime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genres.isNotEmpty) ...[
          _buildGenreChips(genres.map((g) => g.name ?? '').where((n) => n.isNotEmpty).toList()),
          const SizedBox(height: 16),
        ],
        if (runtime != null && runtime > 0) ...[
          _buildMetaRow([Icons.timer_outlined], ['$runtime ${'info_min'.tr()}']),
          const SizedBox(height: 16),
        ],
        if (directors.isNotEmpty) ...[
          _buildSectionLabel('director'.tr()),
          const SizedBox(height: 12),
          _buildPersonRow(directors
              .map((d) => _PersonItem(id: d.id, name: d.name, profilePath: d.profilePath, role: 'director'))
              .toList()),
          const SizedBox(height: 20),
        ],
        if (topCast.isNotEmpty) ...[
          _buildSectionLabel('cast'.tr()),
          const SizedBox(height: 12),
          _buildPersonRow(topCast
              .map((a) => _PersonItem(id: a.id, name: a.name, profilePath: a.profilePath, role: 'cast'))
              .toList()),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  // ── TV SHOW: genres + episode runtime + seasons + cast ─────────────────

  Widget _buildSeriesSeasons() {
    final topCast = _credits?.cast?.take(15).toList() ?? [];
    final seasons = _seriesDetails?.seasons?.where((s) => (s.seasonNumber ?? 0) > 0).toList() ?? [];
    final genres = _seriesDetails?.genres ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genres.isNotEmpty) ...[
          _buildGenreChips(genres.map((g) => g.name ?? '').where((n) => n.isNotEmpty).toList()),
          const SizedBox(height: 16),
        ],
        if (seasons.isNotEmpty) ...[
          _buildSectionLabel('info_seasons'.tr()),
          const SizedBox(height: 12),
          ...seasons.map((s) => _buildSeasonRow(s)),
          const SizedBox(height: 20),
        ],
        if (topCast.isNotEmpty) ...[
          _buildSectionLabel('cast'.tr()),
          const SizedBox(height: 12),
          _buildPersonRow(topCast
              .map((a) => _PersonItem(id: a.id, name: a.name, profilePath: a.profilePath, role: 'cast'))
              .toList()),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildSeasonRow(Seasons season) {
    final seasonNum = season.seasonNumber ?? 0;
    final isExpanded = _expandedSeasons.contains(seasonNum);
    final isLoading = _loadingSeasons.contains(seasonNum);
    final episodes = _episodeCache[seasonNum];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tappable header row
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            if (isExpanded) {
              setState(() => _expandedSeasons.remove(seasonNum));
              return;
            }
            setState(() => _expandedSeasons.add(seasonNum));
            if (!_episodeCache.containsKey(seasonNum)) {
              setState(() => _loadingSeasons.add(seasonNum));
              try {
                final data = await HttpService().fetchSeasonEpisodes(widget.mediaId, seasonNum);
                if (mounted) {
                  setState(() {
                    _episodeCache[seasonNum] = data.episodes ?? [];
                    _loadingSeasons.remove(seasonNum);
                  });
                }
              } catch (_) {
                if (mounted) setState(() => _loadingSeasons.remove(seasonNum));
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'S$seasonNum',
                      style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    season.name ?? 'Season $seasonNum',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (season.episodeCount != null)
                  Text(
                    '${season.episodeCount} ${'info_episodes'.tr()}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[500],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Expanded episode list
        if (isExpanded) ...[
          const SizedBox(height: 4),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (episodes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Column(
                children: _buildEpisodeList(episodes),
              ),
            ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  List<Widget> _buildEpisodeList(List<Episode> episodes) {
    final items = <Widget>[];
    for (int i = 0; i < episodes.length; i++) {
      items.add(_buildEpisodeRow(episodes[i]));
      if (i < episodes.length - 1) {
        items.add(Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[850],
        ));
      }
    }
    return items;
  }

  Widget _buildEpisodeRow(Episode ep) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episode number badge
          SizedBox(
            width: 28,
            child: Text(
              'E${ep.episodeNumber}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Episode name
          Expanded(
            child: Text(
              ep.name ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          // Runtime
          if (ep.runtime != null && ep.runtime! > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${ep.runtime} ${'info_min'.tr()}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── Genre chips ─────────────────────────────────────────────────────────

  Widget _buildGenreChips(List<String> genres) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: genres
          .map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

  // ── Meta row (icon + label) ──────────────────────────────────────────────

  Widget _buildMetaRow(List<IconData> icons, List<String> labels) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: List.generate(icons.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[i], color: Colors.grey[400], size: 15),
            const SizedBox(width: 5),
            Text(
              labels[i],
              style: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
          ],
        );
      }),
    );
  }

  // ── Shared person avatar row ────────────────────────────────────────────

  Widget _buildPersonRow(List<_PersonItem> people) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final person = people[index];
          return GestureDetector(
            onTap: person.id != null
                ? () {
                    UserActionService.logPersonTapped(
                      personId: person.id!,
                      personName: person.name ?? '',
                      role: person.role,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailPage(
                          personId: person.id!,
                          personName: person.name ?? '',
                          profilePath: person.profilePath,
                        ),
                      ),
                    );
                  }
                : null,
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: person.profilePath != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w185${person.profilePath}',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _personPlaceholder(),
                          )
                        : _personPlaceholder(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    person.name ?? '',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 10, height: 1.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _personPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Theme.of(context).colorScheme.tertiary,
      child: Icon(Icons.person, color: Colors.grey[600], size: 28),
    );
  }
}

/// Lightweight data holder for person avatar rows.
class _PersonItem {
  final int? id;
  final String? name;
  final String? profilePath;
  final String role;

  const _PersonItem({required this.id, required this.name, required this.profilePath, required this.role});
}
