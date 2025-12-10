import 'dart:async';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:watch_next/pages/recommendation_loading_page.dart';
import 'package:watch_next/services/feedback_service.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/utils/prompts.dart';
import 'package:watch_next/widgets/feedback_dialog.dart';
import 'package:watch_next/widgets/main_menu/examples_dialog.dart';
import 'package:watch_next/widgets/main_menu/main_menu_top_bar.dart';
import 'package:watch_next/widgets/main_menu/media_type_switch.dart';
import 'package:watch_next/widgets/main_menu/prompt_input_widget.dart';
import 'package:watch_next/widgets/main_menu/query_settings_panel.dart';
import 'package:watch_next/widgets/shared/toast_widget.dart';

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
  bool isValidQuery = false;
  bool enableLoading = false;
  bool noInternet = false;
  int typeIsMovie = 0;
  QuerySettings _querySettings = const QuerySettings();

  @override
  void initState() {
    super.initState();
    openAI = OpenAIClient(apiKey: openApiKey);
    _controller.addListener(_checkLength);
    _loadQuerySettings();
  }

  Future<void> _loadQuerySettings() async {
    final settings = await QuerySettingsService.load();
    if (mounted) {
      setState(() => _querySettings = settings);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkLength() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLongEnough = _controller.text.length >= 5;
        });
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const MainMenuTopBar(),
              const Spacer(),
              _buildDescription(),
              const SizedBox(height: 32),
              MediaTypeSwitch(
                currentIndex: typeIsMovie,
                onToggle: (index) => setState(() => typeIsMovie = index),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  QuerySettingsButton(
                    settings: _querySettings,
                    onSettingsChanged: (settings) {
                      setState(() => _querySettings = settings);
                    },
                    isMovie: typeIsMovie == 0,
                  ),
                  const SizedBox(width: 12),
                  ExamplesButton(isMovie: typeIsMovie == 0),
                ],
              ),
              const SizedBox(height: 16),
              PromptInputWidget(
                controller: _controller,
                textFieldKey: textFieldKey,
                isLongEnough: isLongEnough,
                enableLoading: enableLoading,
                onGoPressed: _onGoPressed,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      "find_something".tr(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.4,
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
          icon: const Icon(Icons.cloud_off, color: Colors.orange, size: 36),
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

    FirebaseFirestore.instance.collection('good_queries').add({
      'type': typeIsMovie == 0 ? "movie" : "show",
      'timestamp': FieldValue.serverTimestamp(),
      'query': _controller.text,
    });

    await FeedbackService.incrementSuccessfulQuery();

    if (!mounted) return;

    // Build the full query with settings suffix
    final fullQuery = _controller.text + _querySettings.toPromptSuffix(isMovie: typeIsMovie == 0);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecommendationLoadingPage(
          requestString: fullQuery,
          type: typeIsMovie,
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

  void _handleInvalidQuery() {
    FirebaseAnalytics.instance.logEvent(
      name: 'invalid_prompt',
      parameters: <String, Object>{
        "type": typeIsMovie == 0 ? "movie" : "show",
      },
    );

    FirebaseFirestore.instance.collection('invalid_queries').add({
      'type': typeIsMovie == 0 ? "movie" : "show",
      'timestamp': FieldValue.serverTimestamp(),
      'query': _controller.text,
    });

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
