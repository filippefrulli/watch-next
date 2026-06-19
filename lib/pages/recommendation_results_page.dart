// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/pages/recommendation_loading_page.dart';
import 'package:watch_next/objects/streaming_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/ratings_service.dart';
import 'package:watch_next/services/streaming_link_service.dart';
import 'package:watch_next/services/not_interested_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/watched_service.dart';
import 'package:watch_next/services/share_service.dart';
import 'package:watch_next/widgets/watched/rating_dialog.dart';
import 'package:watch_next/widgets/shared/confirm_dialog.dart';
import 'package:watch_next/widgets/recommendation_results/recommendation_header.dart';
import 'package:watch_next/widgets/recommendation_results/recommendation_content.dart';
import 'package:watch_next/widgets/recommendation_results/movie_info_panel.dart';
import 'package:watch_next/widgets/recommendation_results/swipe_hint_overlay.dart';

class RecommendationResultsPage extends StatefulWidget {
  final List<WatchObject> watchObjects;
  final String requestString;
  final int type;
  final String itemsToNotRecommend;
  final bool includeRentals;
  final bool includePurchases;
  final bool excludeWatchlist;
  final bool excludeWatched;

  const RecommendationResultsPage({
    super.key,
    required this.watchObjects,
    required this.requestString,
    required this.type,
    required this.itemsToNotRecommend,
    this.includeRentals = false,
    this.includePurchases = false,
    this.excludeWatchlist = true,
    this.excludeWatched = true,
  });

  @override
  State<RecommendationResultsPage> createState() => _RecommendationResultsPageState();
}

class _RecommendationResultsPageState extends State<RecommendationResultsPage> {
  late Future<dynamic> servicesList;
  final WatchlistService _watchlistService = WatchlistService();
  final WatchedService _watchedService = WatchedService();

  int index = 0;
  late int length;
  late WatchObject selectedWatchObject;
  late List<WatchObject> watchObjectsList;
  PanelController pc = PanelController();
  bool _isInWatchlist = false;
  bool _isWatched = false;
  int? _watchedRating;
  bool _isNotInterested = false;
  String? _imdbRating;
  // mediaId → IMDb score (null = looked up, no score). Lets us preload ahead
  // and reuse the (otherwise repeated) IMDb-id + ratings lookups on swipe.
  final Map<int, String?> _ratingCache = {};
  int _hintStep = 0; // 0=none, 1=swipe to browse, 2=swipe up for details

  Future<MovieCredits> movieCredits = Future.value(MovieCredits());

  String? trailerUrl = '';
  String? title = '';

  List<TrailerResults> trailerList = [];
  List<String> trailerImages = [];

  String thumbnail = "https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg";
  String baseUrl = 'https://www.youtube.com/watch?v=';

  @override
  initState() {
    super.initState();
    servicesList = HttpService().getWatchProvidersByLocale();
    watchObjectsList = widget.watchObjects;
    length = watchObjectsList.length;
    selectedWatchObject = watchObjectsList[index];
    _checkIfInWatchlist();
    _checkIfWatched();
    _checkIfNotInterested();
    _loadRating();

    // Preload the first poster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadNextPoster();
    });

    _initHints();
  }

  void _openPanel() {
    movieCredits = HttpService().fetchMovieCredits(selectedWatchObject.id!);
    if (widget.type == 0) {
      HttpService().fetchTrailer(selectedWatchObject.id!).then((value) {
        setState(() => trailerList = value);
        waitForImages();
      });
    } else {
      HttpService().fetchTrailerSeries(selectedWatchObject.id!).then((value) {
        setState(() => trailerList = value);
        waitForImages();
      });
    }
    pc.open();
  }

  Future<void> _initHints() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('swipe_hints_completed') ?? false;
    if (!completed && mounted) setState(() => _hintStep = 1);
  }

  void _advanceHint(int fromStep) {
    if (_hintStep != fromStep) return;
    if (fromStep == 2) {
      setState(() => _hintStep = 0);
      SharedPreferences.getInstance().then((p) => p.setBool('swipe_hints_completed', true));
    } else {
      setState(() => _hintStep = fromStep + 1);
    }
  }

  Future<void> _checkIfInWatchlist() async {
    if (selectedWatchObject.id != null) {
      final inWatchlist = await _watchlistService.isInWatchlist(selectedWatchObject.id!);
      if (mounted) {
        setState(() {
          _isInWatchlist = inWatchlist;
        });
      }
    }
  }

  Future<void> _checkIfWatched() async {
    if (selectedWatchObject.id != null) {
      final item = await _watchedService.getWatchedItem(selectedWatchObject.id!);
      if (mounted) {
        setState(() {
          _isWatched = item != null;
          _watchedRating = item?.rating;
        });
      }
    }
  }

  Future<void> _toggleWatched() async {
    if (selectedWatchObject.id == null) return;
    if (_isWatched) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'remove_from_watched'.tr(),
        subtitle: selectedWatchObject.title,
        confirmLabel: 'remove'.tr(),
        cancelLabel: 'cancel'.tr(),
      );
      if (!confirmed) return;
      await _watchedService.removeFromWatched(selectedWatchObject.id!);
      UserActionService.logWatchedRemove(
        mediaId: selectedWatchObject.id!,
        title: selectedWatchObject.title ?? '',
        type: widget.type == 0 ? 'movie' : 'show',
      );
      if (mounted) {
        setState(() {
          _isWatched = false;
          _watchedRating = null;
        });
      }
    } else {
      final result = await RatingDialog.show(context, title: selectedWatchObject.title ?? '');
      if (result == null) return;
      await _watchedService.markAsWatched(WatchedItem(
        mediaId: selectedWatchObject.id!,
        title: selectedWatchObject.title ?? '',
        isMovie: widget.type == 0,
        posterPath: selectedWatchObject.posterPath,
        rating: result.rating,
        dateWatched: result.dateWatched,
        overview: selectedWatchObject.overview,
      ));
      UserActionService.logWatchedAdd(
        mediaId: selectedWatchObject.id!,
        title: selectedWatchObject.title ?? '',
        type: widget.type == 0 ? 'movie' : 'show',
        rating: result.rating,
        source: 'recommendation',
      );
      if (mounted) {
        setState(() {
          _isWatched = true;
          _watchedRating = result.rating;
        });
      }
    }
  }

  Future<void> _checkIfNotInterested() async {
    final title = selectedWatchObject.title;
    if (title == null) return;
    final result = await NotInterestedService.contains(title);
    if (mounted) setState(() => _isNotInterested = result);
  }

  /// Resolves the IMDb score for a single result, memoised in [_ratingCache]
  /// so each title's IMDb-id + ratings lookup happens at most once.
  Future<String?> _fetchRatingFor(WatchObject obj) async {
    final id = obj.id;
    if (id == null) return null;
    if (_ratingCache.containsKey(id)) return _ratingCache[id];
    try {
      final String? imdbId = widget.type == 0
          ? (await HttpService().fetchMovieDetails(id)).imdbId
          : await HttpService().fetchSeriesImdbId(id);
      final ratings = await RatingsService.fetchByImdbId(imdbId);
      return _ratingCache[id] = ratings.imdb;
    } catch (_) {
      return null; // Score is optional — leave it hidden on failure.
    }
  }

  /// Loads the score for the current result (instant when already cached), then
  /// preloads the next result so the badge is ready by the time you swipe.
  Future<void> _loadRating() async {
    final id = selectedWatchObject.id;
    if (id == null) return;
    final rating = await _fetchRatingFor(selectedWatchObject);
    if (mounted && selectedWatchObject.id == id) {
      setState(() => _imdbRating = rating);
    }
    _preloadNextRating();
  }

  /// Warms the cache for the next result without touching the UI.
  void _preloadNextRating() {
    final next = index + 1;
    if (next < length) _fetchRatingFor(watchObjectsList[next]);
  }

  Future<void> _markNotInterested() async {
    final title = selectedWatchObject.title;
    if (title == null || title.isEmpty) return;

    // Tapping again undoes it, so the title can be recommended once more.
    final undo = _isNotInterested;
    if (undo) {
      await NotInterestedService.removeTitle(title);
    } else {
      await NotInterestedService.addTitle(title);
    }

    if (mounted) {
      setState(() => _isNotInterested = !undo);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            undo ? 'not_interested_undo_toast'.tr() : 'not_interested_toast'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: undo ? Colors.green[700] : Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleWatchlist() async {
    if (selectedWatchObject.id == null) return;

    try {
      if (_isInWatchlist) {
        await _watchlistService.removeFromWatchlist(selectedWatchObject.id!);
        if (mounted) {
          setState(() => _isInWatchlist = false);
        }
        // Track watchlist remove
        UserActionService.logWatchlistRemove(
          mediaId: selectedWatchObject.id!,
          title: selectedWatchObject.title ?? '',
          type: widget.type == 0 ? 'movie' : 'show',
        );
      } else {
        await _watchlistService.addToWatchlist(
          mediaId: selectedWatchObject.id!,
          title: selectedWatchObject.title ?? '',
          isMovie: widget.type == 0,
          posterPath: selectedWatchObject.posterPath,
        );
        if (mounted) {
          setState(() => _isInWatchlist = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'added_to_watchlist'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Track watchlist add
        UserActionService.logWatchlistAdd(
          mediaId: selectedWatchObject.id!,
          title: selectedWatchObject.title ?? '',
          type: widget.type == 0 ? 'movie' : 'show',
          source: 'recommendation',
        );
      }
    } catch (e) {
      // Handle errors if necessary
    }
  }

  Future<void> _shareSelected() async {
    UserActionService.logButtonPressed(buttonName: 'share_media');
    await ShareService.shareMedia(
      title: selectedWatchObject.title ?? '',
      posterPath: selectedWatchObject.posterPath,
      message: 'share_message'.tr(args: [selectedWatchObject.title ?? '', ShareService.storeUrl]),
    );
  }

  Future<void> _openWatchLink() async {
    final providers = selectedWatchObject.watchProviders;
    final title = selectedWatchObject.title;
    if (providers == null || providers.isEmpty || title == null || title.isEmpty) return;
    UserActionService.logButtonPressed(buttonName: 'watch_now_provider');

    // Resolve the name of the provider shown in the widget (the first one).
    String? providerName;
    try {
      final services = await servicesList;
      for (final StreamingService s in services) {
        if (s.providerId == providers.first) {
          providerName = s.providerName;
          break;
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final region = prefs.getString('region') ?? 'DE';

    final uri = StreamingLinkService.searchUrl(
      providerName: providerName,
      title: title,
      region: region,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('could_not_open_link'.tr())),
      );
    }
  }

  // Preload next poster image to cache
  void _preloadNextPoster() {
    if (index < length - 1 && watchObjectsList.isNotEmpty) {
      final nextPoster = watchObjectsList[index + 1].posterPath;
      if (nextPoster != null) {
        final imageUrl = "https://image.tmdb.org/t/p/original//$nextPoster";
        precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          SlidingUpPanel(
            controller: pc,
            margin: const EdgeInsets.all(8.0),
            panel: MovieInfoPanel(
              mediaId: selectedWatchObject.id!,
              title: selectedWatchObject.title ?? '',
              overview: selectedWatchObject.overview ?? '',
              isMovie: widget.type == 0,
              posterPath: selectedWatchObject.posterPath,
              trailerList: trailerList,
              trailerImages: trailerImages,
              onTrailerTap: _launchURL,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(25),
            ),
            collapsed: Container(),
            minHeight: 0,
            maxHeight: MediaQuery.of(context).size.height * 0.90,
            backdropEnabled: true,
            backdropOpacity: 0.55,
            color: Theme.of(context).colorScheme.primary,
            body: pageBody(),
          ),
          if (_hintStep > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SwipeHintOverlay(key: ValueKey(_hintStep), step: _hintStep, isFirstItem: index == 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget pageBody() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          RecommendationHeader(
            currentIndex: index,
            totalCount: length,
            isLoading: false,
            onShare: _shareSelected,
            onClose: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GestureDetector(
              onPanEnd: (details) {
                final dx = details.velocity.pixelsPerSecond.dx;
                final dy = details.velocity.pixelsPerSecond.dy;
                if (dy.abs() > dx.abs()) {
                  if (dy < -300) {
                    _advanceHint(2);
                    _openPanel();
                  }
                } else {
                  if (dx < -300 && index < length - 1) {
                    _advanceHint(1);
                    setState(() {
                      index++;
                      selectedWatchObject = watchObjectsList[index];
                      _imdbRating = null;
                    });
                    _checkIfInWatchlist();
                    _checkIfWatched();
                    _checkIfNotInterested();
                    _loadRating();
                    _preloadNextPoster();
                  } else if (dx > 300 && index > 0) {
                    _advanceHint(1);
                    setState(() {
                      index--;
                      selectedWatchObject = watchObjectsList[index];
                      _imdbRating = null;
                    });
                    _checkIfInWatchlist();
                    _checkIfWatched();
                    _checkIfNotInterested();
                    _loadRating();
                    _preloadNextPoster();
                  }
                }
              },
              child: RecommendationContent(
              posterPath: selectedWatchObject.posterPath ?? '/h5hVeCfYSb8gIO0F41gqidtb0AI.jpg',
              overview: selectedWatchObject.overview,
              genreIds: selectedWatchObject.genreIds,
              imdbRating: _imdbRating,
              watchProviders: selectedWatchObject.watchProviders,
              servicesList: servicesList,
              currentIndex: index,
              totalCount: length,
              mediaType: widget.type,
              isInWatchlist: _isInWatchlist,
              isWatched: _isWatched,
              watchedRating: _watchedRating,
              isNotInterested: _isNotInterested,
              isRentOnly: selectedWatchObject.isRentOnly,
              isBuyOnly: selectedWatchObject.isBuyOnly,
              onProviderTap: _openWatchLink,
              onWatchlistPressed: _toggleWatchlist,
              onWatchedPressed: _toggleWatched,
              onNotInterestedPressed: _markNotInterested,
              onReloadPressed: () {
                // Navigate back to loading page for new recommendations
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => RecommendationLoadingPage(
                      requestString: widget.requestString,
                      type: widget.type,
                      includeRentals: widget.includeRentals,
                      includePurchases: widget.includePurchases,
                      excludeWatchlist: widget.excludeWatchlist,
                      excludeWatched: widget.excludeWatched,
                      itemsToNotRecommend: widget.itemsToNotRecommend,
                    ),
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  String getDirector(MovieCredits credits) {
    List<Crew>? list = credits.crew;
    int index;
    if (list == null) {
      return "";
    }
    index = list.indexWhere((crew) => crew.job == "Director");

    return list[index].name!;
  }

  Future<void> _launchURL(String trailerUrl) async {
    Uri uri = Uri.parse(baseUrl + trailerUrl);
    if (Platform.isIOS) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw 'Could not launch trailer';
        }
      }
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri';
      }
    }
  }

  Future<void> getTrailerImages() async {
    trailerImages = [];
    for (int i = 0; i < trailerList.length; i++) {
      var jsonData = await HttpService().getDetail(baseUrl + trailerList[i].key!);
      if (jsonData != null) {
        String thumbnail = jsonData['thumbnail_url'];
        trailerImages.add(thumbnail);
      } else {
        trailerImages.add('https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg');
      }
    }
  }

  Future<void> waitForImages() async {
    await getTrailerImages();
    setState(() {});
  }
}

class WatchObject {
  String? posterPath;
  String? overview;
  int? id;
  String? title;
  List<int>? watchProviders;
  List<int>? genreIds;
  bool isRentOnly;
  bool isBuyOnly;

  WatchObject({
    this.posterPath,
    this.overview,
    this.id,
    this.title,
    this.watchProviders,
    this.genreIds,
    this.isRentOnly = false,
    this.isBuyOnly = false,
  });
}
