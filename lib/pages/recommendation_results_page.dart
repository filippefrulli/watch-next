// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/pages/recommendation_loading_page.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/not_interested_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/watched_service.dart';
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
    if (kDebugMode) await prefs.remove('swipe_hints_completed');
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

  Future<void> _markNotInterested() async {
    final title = selectedWatchObject.title;
    if (title == null || title.isEmpty) return;
    await NotInterestedService.addTitle(title);
    if (mounted) {
      setState(() => _isNotInterested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'not_interested_toast'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red[700],
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
              tmdbRating: selectedWatchObject.tmdbRating,
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
                    });
                    _checkIfInWatchlist();
                    _checkIfWatched();
                    _checkIfNotInterested();
                    _preloadNextPoster();
                  } else if (dx > 300 && index > 0) {
                    _advanceHint(1);
                    setState(() {
                      index--;
                      selectedWatchObject = watchObjectsList[index];
                    });
                    _checkIfInWatchlist();
                    _checkIfWatched();
                    _checkIfNotInterested();
                    _preloadNextPoster();
                  }
                }
              },
              child: RecommendationContent(
              posterPath: selectedWatchObject.posterPath ?? '/h5hVeCfYSb8gIO0F41gqidtb0AI.jpg',
              overview: selectedWatchObject.overview,
              genreIds: selectedWatchObject.genreIds,
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
  double? tmdbRating;
  int? id;
  String? title;
  List<int>? watchProviders;
  List<int>? genreIds;
  bool isRentOnly;
  bool isBuyOnly;

  WatchObject({
    this.posterPath,
    this.overview,
    this.tmdbRating,
    this.id,
    this.title,
    this.watchProviders,
    this.genreIds,
    this.isRentOnly = false,
    this.isBuyOnly = false,
  });
}
