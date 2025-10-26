// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/pages/recommendation_loading_page.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/widgets/recommendation_results/recommendation_header.dart';
import 'package:watch_next/widgets/recommendation_results/recommendation_content.dart';
import 'package:watch_next/widgets/recommendation_results/movie_info_panel.dart';

class RecommendationResultsPage extends StatefulWidget {
  final List<WatchObject> watchObjects;
  final String requestString;
  final int type;
  final String itemsToNotRecommend;

  const RecommendationResultsPage({
    super.key,
    required this.watchObjects,
    required this.requestString,
    required this.type,
    required this.itemsToNotRecommend,
  });

  @override
  State<RecommendationResultsPage> createState() => _RecommendationResultsPageState();
}

class _RecommendationResultsPageState extends State<RecommendationResultsPage> {
  late Future<dynamic> servicesList;

  int index = 0;
  late int length;
  late WatchObject selectedWatchObject;
  late List<WatchObject> watchObjectsList;
  PanelController pc = PanelController();

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

    // Preload the first poster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadNextPoster();
    });
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
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: SlidingUpPanel(
        controller: pc,
        margin: const EdgeInsets.all(8.0),
        panel: MovieInfoPanel(
          title: selectedWatchObject.title ?? '',
          overview: selectedWatchObject.overview ?? '',
          tmdbRating: selectedWatchObject.tmdbRating,
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
        backdropOpacity: 0.8,
        color: const Color.fromRGBO(11, 14, 23, 1),
        body: pageBody(),
      ),
    );
  }

  Widget pageBody() {
    return Column(
      children: [
        const SizedBox(height: 24),
        RecommendationHeader(
          currentIndex: index,
          totalCount: length,
          isLoading: false,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RecommendationContent(
            posterPath: selectedWatchObject.posterPath ?? '/h5hVeCfYSb8gIO0F41gqidtb0AI.jpg',
            watchProviders: selectedWatchObject.watchProviders,
            servicesList: servicesList,
            currentIndex: index,
            totalCount: length,
            mediaType: widget.type,
            onPrevious: () {
              setState(() {
                if (index > 0) {
                  index--;
                  selectedWatchObject = watchObjectsList[index];
                }
              });
              _preloadNextPoster();
            },
            onNext: () {
              setState(() {
                if (index < length - 1) {
                  index++;
                  selectedWatchObject = watchObjectsList[index];
                }
              });
              _preloadNextPoster();
            },
            onAccept: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.setInt('accepted_movie', selectedWatchObject.id!);
              if (!mounted) return;
              // Only pop once since loading page used pushReplacement
              Navigator.of(context).pop();
            },
            onInfoPressed: () async {
              movieCredits = HttpService().fetchMovieCredits(selectedWatchObject.id!);
              if (widget.type == 0) {
                HttpService().fetchTrailer(selectedWatchObject.id!).then((value) {
                  setState(() {
                    trailerList = value;
                  });
                  waitForImages();
                });
              } else {
                HttpService().fetchTrailerSeries(selectedWatchObject.id!).then((value) {
                  setState(() {
                    trailerList = value;
                  });
                  waitForImages();
                });
              }
              pc.open();
            },
            onReloadPressed: () {
              // Navigate back to loading page for new recommendations
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => RecommendationLoadingPage(
                    requestString: widget.requestString,
                    type: widget.type,
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

  WatchObject({
    this.posterPath,
    this.overview,
    this.tmdbRating,
    this.id,
    this.title,
    this.watchProviders,
  });
}
