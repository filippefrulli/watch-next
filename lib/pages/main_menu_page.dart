import 'dart:async';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:watch_next/pages/recommendation_loading_page.dart';
import 'package:watch_next/services/feedback_service.dart';
import 'package:watch_next/services/notification_service.dart';
import 'package:watch_next/services/ad_preload_service.dart';
import 'package:watch_next/services/watchlist_service.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/utils/prompts.dart';
import 'package:watch_next/utils/app_colors.dart';
import 'package:watch_next/widgets/feedback_dialog.dart';
import 'package:watch_next/widgets/main_menu/hero_input.dart';
import 'package:watch_next/widgets/main_menu/media_type_switch.dart';
import 'package:watch_next/widgets/main_menu/query_settings_panel.dart';
import 'package:watch_next/widgets/shared/toast_widget.dart';
import 'package:watch_next/pages/settings_page.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  late final OpenAIClient openAI;
  final _controller = TextEditingController();
  final GlobalKey textFieldKey = GlobalKey();

  bool isLongEnough = false;
  bool hasText = false;
  bool isValidQuery = false;
  bool enableLoading = false;
  bool noInternet = false;
  int typeIsMovie = 0;
  QuerySettings _querySettings = const QuerySettings();
  int _exampleIndex = 0;
  Timer? _exampleTimer;

  // Localized example prompts. Counts are fixed (18 movies / 16 shows) so the
  // rotation index math stays valid across locales.
  List<String> get _movieExamples => List.generate(18, (i) => 'example_movie_${i + 1}'.tr());

  List<String> get _showExamples => List.generate(16, (i) => 'example_show_${i + 1}'.tr());

  @override
  void initState() {
    super.initState();
    openAI = OpenAIClient(apiKey: openAiKey);
    _controller.addListener(_checkLength);
    _loadQuerySettings();
    _exampleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          final list = typeIsMovie == 0 ? _movieExamples : _showExamples;
          // Advance by 2 so the whole pair refreshes each cycle.
          _exampleIndex = (_exampleIndex + 2) % list.length;
        });
      }
    });
    // Reschedule notification with proper translations once context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleNotificationWithContext();
    });
  }

  Future<void> _rescheduleNotificationWithContext() async {
    if (mounted) {
      await NotificationService.rescheduleWithTranslations(context);
    }
  }

  Future<void> _loadQuerySettings() async {
    final settings = await QuerySettingsService.load();
    if (mounted) {
      setState(() => _querySettings = settings);
    }
  }

  @override
  void dispose() {
    _exampleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _checkLength() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final wasLongEnough = isLongEnough;
        setState(() {
          isLongEnough = _controller.text.length >= 5;
          hasText = _controller.text.isNotEmpty;
        });
        // Preload the ad the moment the query is long enough
        if (!wasLongEnough && isLongEnough) {
          AdPreloadService.instance.preload(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        resizeToAvoidBottomInset: true,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const tabBarHeight = 70;

    final availableHeight = screenHeight - topPadding - bottomPadding - tabBarHeight - bottomInset;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: availableHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Settings button top-right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSettingsButton(),
                ],
              ),
              const Spacer(flex: 2),
              // Hero headline + subtitle
              _buildHeroHeadline(),
              const SizedBox(height: 10),
              _buildSubtitle(),
              const SizedBox(height: 40),
              // Hero input — the single focal point, with the Movie/TV mode
              // selector and filters living on it as tools.
              HeroInput(
                controller: _controller,
                textFieldKey: textFieldKey,
                isLongEnough: isLongEnough,
                hasText: hasText,
                enableLoading: enableLoading,
                onGoPressed: _onGoPressed,
                isMovie: typeIsMovie == 0,
                hasActiveFilters: _querySettings.hasActiveFilters,
                onFiltersPressed: () {
                  QuerySettingsPanel.show(
                    context,
                    initialSettings: _querySettings,
                    onSettingsChanged: (settings) {
                      setState(() => _querySettings = settings);
                    },
                    isMovie: typeIsMovie == 0,
                  );
                },
                modeSelector: MediaTypeSwitch(
                  currentIndex: typeIsMovie,
                  onToggle: (index) => setState(() {
                    typeIsMovie = index;
                    _exampleIndex = 0;
                  }),
                ),
              ),
              const SizedBox(height: 36),
              // Tappable suggestion launchpad (replaces the step guide)
              _buildSuggestionChips(),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeadline() {
    return Text(
      "main_headline".tr(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'step_2'.tr(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appColors.textSecondary,
        fontSize: 14,
        height: 1.3,
      ),
    );
  }

  /// A small launchpad of tappable example prompts. They teach by example and
  /// double as one-tap actions, replacing the old numbered step guide.
  Widget _buildSuggestionChips() {
    final list = typeIsMovie == 0 ? _movieExamples : _showExamples;
    final picks = List.generate(2, (i) => list[(_exampleIndex + i) % list.length]);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey('$typeIsMovie-$_exampleIndex'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'examples'.tr(),
              style: TextStyle(
                color: context.appColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final ex in picks) _buildSuggestionRow(ex),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.appColors.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _controller.text = example;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: example.length),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: context.appColors.accent.withValues(alpha: 0.85), size: 15),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    example,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appColors.textPrimary, fontSize: 13, height: 1.3),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.north_east_rounded, color: context.appColors.textTertiary, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => noInternet = false);
      }
    } on SocketException catch (_) {
      setState(() => noInternet = true);
    }
  }

  Future<void> _validateQuery() async {
    try {
      final response = await openAI.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-5-mini'),
          messages: [
            ChatCompletionMessage.system(
              content: typeIsMovie == 0 ? validationPromptMovie : validationPromptSeries,
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(_controller.text),
            ),
          ],
          reasoningEffort: ReasoningEffort.low,
        ),
      );

      if (mounted) {
        setState(() {
          isValidQuery = response.choices.first.message.content == "YES";
          enableLoading = false;
        });
      }
    } catch (e) {
      FirebaseAnalytics.instance.logEvent(
        name: 'api_error',
        parameters: <String, Object>{
          'error': 'validation_query_failed',
          'message': e.toString(),
        },
      );

      if (mounted) {
        setState(() => enableLoading = false);
        showToastWidget(
          ToastWidget(
            title: "error_occurred".tr(),
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 36),
          ),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<void> _onGoPressed() async {
    FocusScope.of(context).unfocus();
    await _checkConnection();

    if (noInternet) {
      showToastWidget(
        ToastWidget(
          title: "connect_to_internet".tr(),
          icon: Icon(Icons.cloud_off, color: context.appColors.accent, size: 36),
        ),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (!isLongEnough || !mounted) return;

    setState(() {
      enableLoading = true;
      isValidQuery = false;
    });

    await _validateQuery();
    if (!mounted) return;

    if (isValidQuery) {
      await _handleValidQuery();
    } else {
      _handleInvalidQuery();
    }
  }

  Future<void> _handleValidQuery() async {
    FirebaseAnalytics.instance.logEvent(
      name: 'valid_prompt',
      parameters: <String, Object>{
        "type": typeIsMovie == 0 ? "movie" : "show",
      },
    );

    await FeedbackService.incrementSuccessfulQuery();

    if (!mounted) return;

    // Build the full query with settings suffix
    final fullQuery = _controller.text + _querySettings.toPromptSuffix(isMovie: typeIsMovie == 0);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecommendationLoadingPage(
          requestString: fullQuery,
          type: typeIsMovie,
          includeRentals: _querySettings.includeRentals,
          includePurchases: _querySettings.includePurchases,
          excludeWatchlist: _querySettings.excludeWatchlist,
          excludeWatched: _querySettings.excludeWatched,
        ),
      ),
    );

    if (mounted) {
      final shouldShow = await FeedbackService.shouldShowFeedbackDialog();
      if (shouldShow && mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const FeedbackDialog(),
            );
          }
        });
      }
    }
  }

  Future<void> _handleInvalidQuery() async {
    FirebaseAnalytics.instance.logEvent(
      name: 'invalid_prompt',
      parameters: <String, Object>{
        "type": typeIsMovie == 0 ? "movie" : "show",
      },
    );

    // Skip Firestore writes in debug mode
    if (!kDebugMode) {
      FirebaseFirestore.instance.collection('invalid_queries').add({
        'type': typeIsMovie == 0 ? "movie" : "show",
        'timestamp': FieldValue.serverTimestamp(),
        'query': _controller.text,
        'identifier': await WatchlistService().getUserId()
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                "invalid_query".tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
