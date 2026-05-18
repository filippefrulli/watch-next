import 'dart:io';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/region.dart';
import 'package:watch_next/pages/recommendation_results_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/ad_preload_service.dart';
import 'package:watch_next/services/purchase_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/query_cache_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/not_interested_service.dart';
import 'package:watch_next/services/watched_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:watch_next/utils/prompts.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/utils/app_colors.dart';

class RecommendationLoadingPage extends StatefulWidget {
  final String requestString;
  final int type;
  final bool includeRentals;
  final bool includePurchases;
  final bool excludeWatchlist;
  final bool excludeWatched;
  final String itemsToNotRecommend;

  const RecommendationLoadingPage({
    super.key,
    required this.requestString,
    required this.type,
    this.includeRentals = false,
    this.includePurchases = false,
    this.excludeWatchlist = true,
    this.excludeWatched = true,
    this.itemsToNotRecommend = '',
  });

  @override
  State<RecommendationLoadingPage> createState() => _RecommendationLoadingPageState();
}

class _RecommendationLoadingPageState extends State<RecommendationLoadingPage> {
  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;
  Color? _adBgColor;

  // Use test ad for debugging - switch to production ad for release
  final String _adUnitId = Platform.isAndroid
      ? androidAd //'ca-app-pub-3940256099942544/2247696110' Test ad for Android
      : iosAd; //'ca-app-pub-3940256099942544/3986624511'; Test ad for iOS

  bool askingGpt = false;
  bool fetchingMovieInfo = false;
  bool filtering = false;
  late String itemsToNotRecommend;
  bool _adLoaded = false;
  bool _noStreamingMatch = false;

  @override
  void initState() {
    super.initState();
    itemsToNotRecommend = widget.itemsToNotRecommend;
    _loadRecommendations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adLoaded) {
      _adLoaded = true;
      if (kDebugMode || PurchaseService.adsRemoved) return;
      final preloaded = AdPreloadService.instance.consume();
      if (preloaded != null) {
        // Ad was preloaded while user was typing — show immediately
        debugPrint('✅ Using preloaded ad');
        setState(() {
          nativeAd = preloaded;
          _nativeAdIsLoaded = true;
        });
      } else {
        // Fallback: start loading now
        debugPrint('⚠️ No preloaded ad, loading fresh');
        _adBgColor = Theme.of(context).colorScheme.primary;
        loadAd();
      }
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
        // Get user's streaming service names for logging
        final userServiceIds = await DatabaseService.getStreamingServicesIds();
        final allProviders = await HttpService().getWatchProvidersByLocale();
        final userServiceNames = allProviders
            .where((provider) => userServiceIds.contains(provider.providerId))
            .map((provider) => provider.providerName ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        // Track user action
        UserActionService.logRecommendationRequested(
          query: widget.requestString,
          type: widget.type == 0 ? 'movie' : 'show',
          includeRentals: widget.includeRentals,
          includePurchases: widget.includePurchases,
          streamingServices: userServiceNames,
        );

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
              excludeWatchlist: widget.excludeWatchlist,
              excludeWatched: widget.excludeWatched,
            ),
          ),
        );
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: _noStreamingMatch ? 'no_movies'.tr() : 'no_titles_found'.tr(),
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
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
        child: Column(
          children: [
            // Ad fills all available space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ValueListenableBuilder<bool>(
                  valueListenable: PurchaseService.adsRemovedNotifier,
                  builder: (context, adsRemoved, _) {
                    if (adsRemoved || !_nativeAdIsLoaded || nativeAd == null) {
                      return const SizedBox.shrink();
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AdWidget(ad: nativeAd!),
                    );
                  },
                ),
              ),
            ),
            // Progress strip at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.threeArchedCircle(color: Colors.white, size: 36),
                  const SizedBox(height: 16),
                  // Step label
                  Text(
                    askingGpt
                        ? "generating".tr()
                        : fetchingMovieInfo
                            ? "fetching".tr()
                            : filtering
                                ? "filtering".tr()
                                : '',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Step dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepDot(active: askingGpt || fetchingMovieInfo || filtering),
                      const SizedBox(width: 8),
                      _stepDot(active: fetchingMovieInfo || filtering),
                      const SizedBox(width: 8),
                      _stepDot(active: filtering),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? context.appColors.accent : context.appColors.inactive,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<List<WatchObject>> askLLM() async {
    setState(() {
      askingGpt = true;
    });

    try {
      // Load cached excluded titles for this query
      final cachedTitles = await QueryCacheService.getExcludedTitles(
        widget.type,
        widget.requestString,
      );

      // Format excluded titles for the prompt
      final excludedTitlesStr = QueryCacheService.formatExcludedTitlesForPrompt(cachedTitles);
      // Also exclude any seed titles passed in (e.g. the movie we're finding similars for)
      final seedExclusion = widget.itemsToNotRecommend.isNotEmpty ? widget.itemsToNotRecommend : '';
      // Exclude titles already in the user's watchlist or watched history
      final watchlistItems =
          widget.excludeWatchlist ? await WatchlistService().getWatchlist().first : <WatchlistItem>[];
      final watchlistTitles = watchlistItems.take(50).map((i) => i.title).join(', ');
      final watchedItems = widget.excludeWatched ? await WatchedService().getWatchedList() : <WatchedItem>[];
      final watchedTitles = watchedItems.take(50).map((i) => i.title).join(', ');
      final notInterestedTitles = await NotInterestedService.getTitles();
      final notInterestedStr = notInterestedTitles.join(', ');
      final allExcluded = [
        if (excludedTitlesStr.isNotEmpty) excludedTitlesStr,
        if (seedExclusion.isNotEmpty) seedExclusion,
        if (watchlistTitles.isNotEmpty) watchlistTitles,
        if (watchedTitles.isNotEmpty) watchedTitles,
        if (notInterestedStr.isNotEmpty) notInterestedStr,
      ].join(', ');
      String doNotRecommend = allExcluded.isNotEmpty ? doNotRecommendPrefix + allExcluded : '';

      // Check if user has limited streaming services (1-2) and add priority instruction
      String priorityInstruction = '';
      final userServiceIds = await DatabaseService.getStreamingServicesIds();
      if (userServiceIds.length <= 2 && userServiceIds.isNotEmpty) {
        // Get service names from the available providers
        final allProviders = await HttpService().getWatchProvidersByLocale();
        final userServiceNames = allProviders
            .where((provider) => userServiceIds.contains(provider.providerId))
            .map((provider) => provider.providerName ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        if (userServiceNames.isNotEmpty) {
          priorityInstruction = prioritizeServicesPrefix(userServiceNames);
        }
      }

      // Get user's country for regional recommendations
      final prefs = await SharedPreferences.getInstance();
      final regionCode = prefs.getString('region') ?? 'US';
      final region = availableRegions.firstWhere(
        (r) => r.iso == regionCode,
        orElse: () => Region(iso: 'US', englishName: 'United States', foreignName: 'United States'),
      );
      final countryName = region.englishName ?? 'United States';

      // Build taste signals from watched history
      final watchedService = WatchedService();
      final highlyRated = await watchedService.getHighlyRatedItems(threshold: 7);
      final lowRated = await watchedService.getLowRatedItems(threshold: 5);
      String tasteSignals = '';
      if (highlyRated.isNotEmpty) {
        final liked = highlyRated.take(10).map((i) => i.title).join(', ');
        tasteSignals +=
            'TASTE SIGNALS: The user has highly rated these titles (score ≥7/10): $liked. Recommend titles with similar themes, tone, or style. ';
      }
      if (lowRated.isNotEmpty) {
        final disliked = lowRated.take(5).map((i) => i.title).join(', ');
        tasteSignals += 'The user gave low ratings to: $disliked. Avoid recommending titles too similar to these. ';
      }

      String queryContent = widget.type == 0
          ? '${moviePrompt1(countryName)} ${widget.requestString}. $moviePrompt2 $tasteSignals$priorityInstruction$doNotRecommend'
          : '${seriesPrompt1(countryName)} ${widget.requestString}. $seriesPrompt2 $tasteSignals$priorityInstruction$doNotRecommend';

      // Determine which LLM provider to use via Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      final llmProvider = remoteConfig.getString('llm_provider');

      String responseContent;
      if (llmProvider == 'gemini') {
        // Gemini API call
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
        responseContent = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        if (responseContent.isEmpty) {
          throw Exception('Empty response from Gemini API');
        }
      } else {
        // OpenAI API call (default)
        final openAI = OpenAIClient(apiKey: openAiKey);
        final openAiResponse = await openAI.createChatCompletion(
          request: CreateChatCompletionRequest(
            model: ChatCompletionModel.modelId('gpt-5-mini'),
            messages: [
              ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.string(queryContent),
              ),
            ],
            reasoningEffort: ReasoningEffort.low,
          ),
        );
        responseContent = openAiResponse.choices.first.message.content ?? '';

        if (responseContent.isEmpty) {
          throw Exception('Empty response from OpenAI API');
        }
      }

      // Parse titles from response and add to cache
      final newTitles = QueryCacheService.parseTitlesFromResponse(responseContent);
      await QueryCacheService.addExcludedTitles(
        widget.type,
        widget.requestString,
        newTitles,
      );

      // Update local state for passing to results page
      itemsToNotRecommend = responseContent;

      setState(() {
        askingGpt = false;
      });

      final parsed = await parseResponse(responseContent);
      if (parsed.isEmpty) return [];
      final filtered = await filterProviders(parsed);

      // Hard filter: remove any result the user already has in their watchlist or watched history
      final watchlistIds = watchlistItems.map((i) => i.mediaId).toSet();
      final watchedIds = watchedItems.map((i) => i.mediaId).toSet();
      final excludedIds = watchlistIds.union(watchedIds);
      return filtered.where((w) => w.id == null || !excludedIds.contains(w.id)).toList();
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
      return [];
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
              genreIds: movieResult.genreIds,
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
              genreIds: seriesResult.genreIds,
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

    if (watchObjectsWithProviders.isEmpty) {
      _noStreamingMatch = true;
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
          // Retry once after a short delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && !_nativeAdIsLoaded) loadAd();
          });
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
        mainBackgroundColor: _adBgColor!,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: AppColors.defaults.accent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.defaults.accent,
          backgroundColor: _adBgColor!,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: _adBgColor!,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey.shade400,
          backgroundColor: _adBgColor!,
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
      ),
    )..load();
  }
}
