import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:watch_next/pages/recommandation_results_page.dart';
import 'package:watch_next/services/http_service.dart';

class RecommendationLoadingPage extends StatefulWidget {
  final String requestString;
  final int type;

  const RecommendationLoadingPage({
    super.key,
    required this.requestString,
    required this.type,
  });

  @override
  State<RecommendationLoadingPage> createState() => _RecommendationLoadingPageState();
}

class _RecommendationLoadingPageState extends State<RecommendationLoadingPage> {
  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;

  // Use test ad for debugging - switch to production ad for release
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110' //Test ad for Android
      : 'ca-app-pub-3940256099942544/3986624511'; //Test ad for iOS

  bool askingGpt = false;
  bool fetchingMovieInfo = false;
  bool filtering = false;
  String itemsToNotRecommend = '';

  @override
  void initState() {
    super.initState();
    loadAd();
    _loadRecommendations();
  }

  @override
  void dispose() {
    nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final results = await askLLM();

      if (!mounted) return;

      if (results.isNotEmpty) {
        // Navigate to results page with the loaded data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RecommendationResultsPage(
              watchObjects: results,
              requestString: widget.requestString,
              type: widget.type,
              itemsToNotRecommend: itemsToNotRecommend,
            ),
          ),
        );
      }
    } catch (e) {
      // Error handling is done in askLLM
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_nativeAdIsLoaded)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 280,
                            minHeight: 250,
                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                            maxHeight: 350,
                          ),
                          child: AdWidget(ad: nativeAd!),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Advertisement',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                LoadingAnimationWidget.threeArchedCircle(
                  color: Colors.orange,
                  size: 50,
                ),
                const SizedBox(height: 24),
                if (askingGpt)
                  Text(
                    "generating".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                if (fetchingMovieInfo)
                  Text(
                    "fetching".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                if (filtering)
                  Text(
                    "filtering".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<WatchObject>> askLLM() async {
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

      // Initialize the Gemini Developer API backend service
      // Create a `GenerativeModel` instance with a model that supports your use case
      final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');

      String queryContent = widget.type == 0
          ? 'prompt_1'.tr() + ' ' + widget.requestString + '. ' + 'prompt_2'.tr() + ' ' + doNotRecomment
          : 'prompt_series_1'.tr() + ' ' + widget.requestString + '. ' + 'prompt_series_2'.tr() + ' ' + doNotRecomment;

      final prompt = [Content.text(queryContent)];

      try {
        final response = await model.generateContent(prompt);

        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from AI model');
        }

        print('RESPONSE_TEXT:${response.text}');
        itemsToNotRecommend = '';
        final responseContent = response.text!;

        setState(() {
          askingGpt = false;
          itemsToNotRecommend = responseContent;
        });

        final parsed = await parseResponse(responseContent);
        return await filterProviders(parsed);
      } on FormatException catch (e) {
        debugPrint('❌ Format error from AI: $e');
        throw Exception('Invalid response format from AI: $e');
      } on Exception catch (e) {
        debugPrint('❌ AI generation error: $e');
        throw Exception('AI generation failed: $e');
      }
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

      debugPrint('❌ Full error details: $e');

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
        fontSize: 16.0,
      );
      return [];
    }

    return watchObjectsWithProviders;
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
          debugPrint('❌ Ad failed to load: ${error.code} - ${error.message}');
          debugPrint('Domain: ${error.domain}');
          ad.dispose();
        },
        onAdClicked: (ad) {
          debugPrint('Ad clicked');
        },
        onAdImpression: (ad) {
          debugPrint('Ad impression');
        },
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
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
