// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/widgets/recommendation_results/recommendation_header.dart';
import 'package:watch_next/widgets/recommendation_results/recommendation_content.dart';
import 'package:watch_next/widgets/recommendation_results/loading_state_widget.dart';
import 'package:watch_next/widgets/recommendation_results/error_state_widget.dart';
import 'package:watch_next/widgets/recommendation_results/movie_info_panel.dart';

class RecommandationResultsPage extends StatefulWidget {
  final String requestString;
  final int type;

  const RecommandationResultsPage({super.key, required this.requestString, required this.type});

  @override
  State<RecommandationResultsPage> createState() => _RecommandationResultsPageState();
}

class _RecommandationResultsPageState extends State<RecommandationResultsPage> {
  late final OpenAIClient openAI;

  late Future<dynamic> servicesList;

  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;

  final String _adUnitId = Platform.isAndroid ? androidAd : iosAd;
  //final String _adUnitId = 'ca-app-pub-3940256099942544/2247696110';

  int index = 0;
  int length = 0;
  bool askingGpt = false;
  bool fetchingMovieInfo = false;
  bool filtering = false;
  WatchObject selectedWatchObject = WatchObject();
  List<WatchObject> watchObjectsList = [];
  PanelController pc = PanelController();
  String responseItems = '';
  String itemsToNotRecommend = '';

  late Future<dynamic> resultList;
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
    openAI = OpenAIClient(apiKey: openApiKey);
    loadAd();
    servicesList = HttpService().getWatchProvidersByLocale();
    resultList = askGpt();
  }

  @override
  void dispose() {
    nativeAd?.dispose();
    super.dispose();
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
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            return RecommendationHeader(
              currentIndex: index,
              totalCount: length,
              isLoading: filtering || fetchingMovieInfo || askingGpt,
            );
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: resultList,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorStateWidget(
                  onRetry: () {
                    setState(() {
                      resultList = askGpt();
                    });
                  },
                );
              }

              if (snapshot.hasData) {
                if (!filtering && !fetchingMovieInfo && !askingGpt) {
                  length = snapshot.data?.length ?? 0;
                  watchObjectsList = snapshot.data ?? [];
                  selectedWatchObject = snapshot.data[index];

                  // Preload next poster after current frame is rendered
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _preloadNextPoster();
                  });

                  return RecommendationContent(
                    posterPath: selectedWatchObject.posterPath ?? '/h5hVeCfYSb8gIO0F41gqidtb0AI.jpg',
                    watchProviders: selectedWatchObject.watchProviders,
                    servicesList: servicesList,
                    currentIndex: index,
                    totalCount: length,
                    mediaType: widget.type,
                    onPrevious: () {
                      setState(() {
                        if (index > 0) index--;
                      });
                      _preloadNextPoster();
                    },
                    onNext: () {
                      setState(() {
                        if (index < length - 1) index++;
                      });
                      _preloadNextPoster();
                    },
                    onAccept: () async {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setInt('accepted_movie', selectedWatchObject.id!);
                      if (!context.mounted) return;
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
                      setState(() {
                        index = 0;
                        watchObjectsList = [];
                        resultList.whenComplete(() => []);
                        resultList = askGpt();
                      });
                    },
                  );
                } else {
                  return LoadingStateWidget(
                    nativeAdIsLoaded: _nativeAdIsLoaded,
                    nativeAd: nativeAd,
                    askingGpt: askingGpt,
                    fetchingMovieInfo: fetchingMovieInfo,
                    filtering: filtering,
                  );
                }
              } else {
                return LoadingStateWidget(
                  nativeAdIsLoaded: _nativeAdIsLoaded,
                  nativeAd: nativeAd,
                  askingGpt: askingGpt,
                  fetchingMovieInfo: fetchingMovieInfo,
                  filtering: filtering,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<dynamic> askGpt() async {
    setState(() {
      askingGpt = true;
    });

    try {
      List<String> itemsList = itemsToNotRecommend.split(',,');
      itemsToNotRecommend = '';
      for (String item in itemsList) {
        if (item.isNotEmpty) {
          itemsToNotRecommend += '${item.substring(
            0,
            item.indexOf('y:'),
          )},';
        }
      }
      String doNotRecomment = itemsToNotRecommend.isNotEmpty ? 'do_not_recommend'.tr() + itemsToNotRecommend : '';

      String queryContent = widget.type == 0
          ? 'prompt_1'.tr() + ' ' + widget.requestString + '. ' + 'prompt_2'.tr() + ' ' + doNotRecomment
          : 'prompt_series_1'.tr() + ' ' + widget.requestString + '. ' + 'prompt_series_2'.tr() + ' ' + doNotRecomment;

      final response = await openAI.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-5-nano'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(queryContent),
            ),
          ],
          reasoningEffort: ReasoningEffort.low,
        ),
      );

      itemsToNotRecommend = '';

      final responseContent = response.choices.first.message.content ?? '';

      setState(() {
        askingGpt = false;
        itemsToNotRecommend = responseContent;
      });

      return parseResponse(responseContent).then(
        (value) => filterProviders(value),
      );
    } catch (e) {
      // Log error to Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'api_error',
        parameters: <String, Object>{
          'error': 'gpt_request_failed',
          'type': widget.type == 0 ? 'movie' : 'show',
          'message': e.toString(),
        },
      );

      setState(() {
        askingGpt = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "error_occurred".tr(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      return [];
    }
  }

  Future<List<WatchObject>> parseResponse(String response) async {
    setState(() {
      fetchingMovieInfo = true;
    });

    List<String> responseTitles = response.split(',,');
    if (responseTitles.isEmpty) {
      FirebaseAnalytics.instance.logEvent(name: 'empty_results', parameters: {
        'type': widget.type == 0 ? 'movie' : 'show',
        'query': widget.requestString,
      });
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: "prompt_issue".tr(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    // Parallelize HTTP requests using Future.wait
    final futures = responseTitles.map((movieTitle) async {
      List<String> list = movieTitle.split('y:');
      if (list.length > 1) {
        if (widget.type == 0) {
          final movieResult = await HttpService().findMovieByTitle(list[0], list[1]);
          if (movieResult.id != null) {
            return WatchObject(
              posterPath: movieResult.posterPath,
              overview: movieResult.overview,
              tmdbRating: movieResult.voteAverage,
              id: movieResult.id,
              title: movieResult.title,
            );
          }
        } else {
          final seriesResult = await HttpService().findShowByTitle(list[0], list[1]);
          if (seriesResult.id != null) {
            return WatchObject(
              posterPath: seriesResult.posterPath,
              overview: seriesResult.overview,
              tmdbRating: seriesResult.voteAverage,
              id: seriesResult.id,
              title: seriesResult.name,
            );
          }
        }
      }
      return null;
    }).toList();

    final results = await Future.wait(futures);
    final watchObjectsList = results.whereType<WatchObject>().toList();

    setState(() {
      fetchingMovieInfo = false;
    });

    return watchObjectsList;
  }

  Future<List<WatchObject>> filterProviders(List<WatchObject> watchObjectList) async {
    setState(() {
      filtering = true;
    });

    // Parallelize HTTP requests using Future.wait
    final futures = watchObjectList.map((watchObject) async {
      if (widget.type == 0) {
        final value = await HttpService().getWatchProviders(
          watchObject.id!,
        );
        if (value.isNotEmpty) {
          watchObject.watchProviders = value;
          return watchObject;
        }
      } else {
        final value = await HttpService().getWatchProvidersSeries(
          watchObject.id!,
        );
        if (value.isNotEmpty) {
          watchObject.watchProviders = value;
          return watchObject;
        }
      }
      return null;
    }).toList();

    final results = await Future.wait(futures);
    final watchObjectsWithProviders = results.whereType<WatchObject>().toList();

    setState(() {
      filtering = false;
    });

    if (watchObjectsWithProviders.isEmpty && mounted) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
          msg: "no_movies".tr(),
          timeInSecForIosWeb: 4,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return [];
    }

    return watchObjectsWithProviders;
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

  void loadAd() {
    nativeAd = NativeAd(
      adUnitId: _adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
      ),
      request: const AdRequest(),
      // Styling
      nativeTemplateStyle: NativeTemplateStyle(
        // Required: Choose a template.
        templateType: TemplateType.medium,
        // Optional: Customize the ad's style.
        mainBackgroundColor: const Color.fromRGBO(11, 14, 23, 1),
        cornerRadius: 15.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[900],
          backgroundColor: Colors.orange,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.orange,
          backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
          style: NativeTemplateFontStyle.italic,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[200],
          backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[200],
          backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
      ),
    )..load();
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
