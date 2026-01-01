import 'dart:io';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/region.dart';
import 'package:watch_next/pages/recommandation_results_page.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/utils/prompts.dart';
import 'package:watch_next/utils/secrets.dart';

class RecommendationLoadingPage extends StatefulWidget {
  final String requestString;
  final int type;
  final bool includeRentals;
  final bool includePurchases;

  const RecommendationLoadingPage({
    super.key,
    required this.requestString,
    required this.type,
    this.includeRentals = false,
    this.includePurchases = false,
  });

  @override
  State<RecommendationLoadingPage> createState() => _RecommendationLoadingPageState();
}

class _RecommendationLoadingPageState extends State<RecommendationLoadingPage> {
  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;

  // Use test ad for debugging - switch to production ad for release
  final String _adUnitId = Platform.isAndroid
      ? androidAd //'ca-app-pub-3940256099942544/2247696110' Test ad for Android
      : iosAd; //'ca-app-pub-3940256099942544/3986624511'; Test ad for iOS

  bool askingGpt = false;
  bool fetchingMovieInfo = false;
  bool filtering = false;
  String itemsToNotRecommend = '';
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adLoaded) {
      _adLoaded = true;
      loadAd();
    }
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
              includeRentals: widget.includeRentals,
              includePurchases: widget.includePurchases,
            ),
          ),
        );
      } else {
        // If results are empty but no error was thrown, navigate back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Error handling is done in askLLM
      // This catch ensures the app doesn't crash if an error propagates here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.outline,
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
      String doNotRecommend = itemsToNotRecommend.isNotEmpty ? doNotRecommendPrefix + itemsToNotRecommend : '';

      // Get user's country for regional recommendations
      final prefs = await SharedPreferences.getInstance();
      final regionCode = prefs.getString('region') ?? 'US';
      final region = availableRegions.firstWhere(
        (r) => r.iso == regionCode,
        orElse: () => Region(iso: 'US', englishName: 'United States', foreignName: 'United States'),
      );
      final countryName = region.englishName ?? 'United States';

      String queryContent = widget.type == 0
          ? '${moviePrompt1(countryName)} ${widget.requestString}. $moviePrompt2 $doNotRecommend'
          : '${seriesPrompt1(countryName)} ${widget.requestString}. $seriesPrompt2 $doNotRecommend';

      // Direct HTTP request to Gemini API
      final url =
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent');

      final response = await http.post(
        url,
        headers: {
          'x-goog-api-key': geminiApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': queryContent}
              ]
            }
          ],
          'generationConfig': {
            'thinkingConfig': {'thinkingLevel': 'low'}
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API request failed: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final responseContent = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

      if (responseContent.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      itemsToNotRecommend = '';

      setState(() {
        askingGpt = false;
        itemsToNotRecommend = responseContent;
      });

      final parsed = await parseResponse(responseContent);
      return await filterProviders(parsed);
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
          msg: "invalid_query".tr(),
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
      FirebaseAnalytics.instance.logEvent(
        name: 'empty_results',
        parameters: {
          'type': widget.type == 0 ? 'movie' : 'show',
          'query': widget.requestString,
        },
      );
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
        final result = await HttpService().getWatchProviders(
          watchObject.id!,
          includeRentals: widget.includeRentals,
          includePurchases: widget.includePurchases,
        );
        if (result.providerIds.isNotEmpty) {
          watchObject.watchProviders = result.providerIds;
          watchObject.isRentOnly = result.isRentOnly;
          watchObject.isBuyOnly = result.isBuyOnly;
          return watchObject;
        }
      } else {
        final result = await HttpService().getWatchProvidersSeries(
          watchObject.id!,
          includeRentals: widget.includeRentals,
          includePurchases: widget.includePurchases,
        );
        if (result.providerIds.isNotEmpty) {
          watchObject.watchProviders = result.providerIds;
          watchObject.isRentOnly = result.isRentOnly;
          watchObject.isBuyOnly = result.isBuyOnly;
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
        mainBackgroundColor: Theme.of(context).colorScheme.primary,
        cornerRadius: 15.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.orange,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.orange,
          backgroundColor: Theme.of(context).colorScheme.primary,
          style: NativeTemplateFontStyle.italic,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[200],
          backgroundColor: Theme.of(context).colorScheme.primary,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[200],
          backgroundColor: Theme.of(context).colorScheme.primary,
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
      ),
    )..load();
  }
}
