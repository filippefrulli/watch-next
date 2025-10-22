import 'dart:async';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:watch_next/pages/recommandation_results_page.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/widgets/toast_widget.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int currentIndex = -1;

  late final OpenAIClient openAI;

  final _controller = TextEditingController();

  bool isLongEnough = false;
  bool isValidQuery = false;
  bool enableLoading = false;

  GlobalKey textFieldKey = GlobalKey();
  GlobalKey goButtonKey = GlobalKey();

  bool noInternet = false;
  int typeIsMovie = 0; //0 = movie , 1 = show

  @override
  void initState() {
    super.initState();
    openAI = OpenAIClient(apiKey: openApiKey);
    _controller.addListener(checkLength);
    _controller.text = '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: body(),
    );
  }

  Widget body() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            topBar(),
            titleSection(),
            Expanded(
              child: Container(),
            ),
            description(),
            const SizedBox(height: 32),
            switchWidget(),
            Expanded(
              child: Container(),
            ),
            examplesWidget(),
            const SizedBox(
              height: 16,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: promptInput(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Placeholder for symmetry
        const SizedBox(width: 48, height: 48),
        Expanded(
          child: Container(),
        ),
        settingsButton(),
      ],
    );
  }

  Widget settingsButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'opened_settings',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
          child: Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget examplesWidget() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(25),
        ),
        child: IconButton(
          icon: Icon(
            Icons.help_outline_rounded,
            color: Colors.grey[900],
            size: 26,
          ),
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'opened_examples',
              parameters: <String, Object>{
                "type": typeIsMovie == 0 ? "movie" : "show",
              },
            );
            typeIsMovie == 0 ? showExamples() : showExamplesShows();
          },
        ),
      ),
    );
  }

  Widget switchWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: ToggleSwitch(
        minWidth: 140.0,
        minHeight: 48.0,
        initialLabelIndex: typeIsMovie,
        cornerRadius: 12.0,
        animate: true,
        animationDuration: 300,
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.transparent,
        inactiveFgColor: Colors.grey[400],
        totalSwitches: 2,
        labels: ['movie'.tr(), 'tv_show'.tr()],
        customTextStyles: [
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ],
        activeBgColors: [
          [Colors.orange],
          [Colors.orange],
        ],
        onToggle: (index) {
          setState(() {
            typeIsMovie = index!;
          });
        },
      ),
    );
  }

  Widget description() {
    return Column(
      children: [
        Text(
          "find_something".tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  Widget titleSection() {
    return Column(
      children: [
        DelayedDisplay(
          fadingDuration: const Duration(milliseconds: 1000),
          child: Text(
            "hey_there".tr(),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget promptInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width - 88,
          child: TextField(
            key: textFieldKey,
            autofocus: false,
            showCursor: true,
            maxLength: 80,
            maxLines: 3,
            minLines: 1,
            controller: _controller,
            cursorColor: Colors.orange,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: "hint".tr(),
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[300]),
              filled: true,
              fillColor: const Color.fromARGB(255, 44, 46, 56),
              contentPadding: const EdgeInsets.only(left: 14.0, bottom: 10.0, top: 10.0),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              enabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        goButton(),
      ],
    );
  }

  Widget goButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: enableLoading ? Colors.orange.withOpacity(0.8) : (isLongEnough ? Colors.orange : Colors.grey[700]),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: enableLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[900]!),
                ),
              )
            : IconButton(
                key: goButtonKey,
                onPressed: () async {
                  isLongEnough ? goButtonPressed() : null;
                },
                icon: Icon(
                  Icons.arrow_forward,
                  size: 32,
                  color: Colors.grey[900],
                ),
              ),
      ),
    );
  }

  void checkLength() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.text.length >= 5 && mounted) {
        setState(() {
          isLongEnough = true;
        });
      }
      if (_controller.text.length < 5 && mounted) {
        setState(() {
          isLongEnough = false;
        });
      }
    });
  }

  Future<void> validateQuery() async {
    try {
      final response = await openAI.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-5-mini'),
          messages: [
            ChatCompletionMessage.system(
              content: typeIsMovie == 0 ? 'validation_prompt'.tr() : 'validation_prompt_series'.tr(),
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(_controller.text),
            ),
          ],
          reasoningEffort: ReasoningEffort.low,
        ),
      );

      if (response.choices.first.message.content == "YES" && mounted) {
        setState(() {
          isValidQuery = true;
          enableLoading = false;
        });
      } else {
        setState(() {
          isValidQuery = false;
          enableLoading = false;
        });
      }
    } catch (e) {
      // Log error to Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'api_error',
        parameters: <String, Object>{
          'error': 'validation_query_failed',
          'message': e.toString(),
        },
      );

      if (mounted) {
        setState(() {
          enableLoading = false;
        });

        // Show user-friendly error message
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

  Future<void> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          noInternet = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        noInternet = true;
      });
    }
  }

  void goButtonPressed() async {
    FirebaseAnalytics.instance.logEvent(
      name: 'go_button_pressed',
      parameters: <String, Object>{
        "type": typeIsMovie == 0 ? "movie" : "show",
      },
    );
    FocusScope.of(context).unfocus();
    await checkConnection();
    if (noInternet) {
      showToastWidget(
        ToastWidget(
          title: "connect_to_internet".tr(),
          icon: const Icon(Icons.cloud_off, color: Colors.orange, size: 36),
        ),
        duration: const Duration(seconds: 4),
      );
    } else {
      if (isLongEnough && mounted) {
        setState(() {
          enableLoading = true;
        });
        await validateQuery();
        if (isValidQuery && mounted) {
          FirebaseAnalytics.instance.logEvent(
            name: 'valid_prompt',
            parameters: <String, Object>{
              "type": typeIsMovie == 0 ? "movie" : "show",
            },
          );

          // Log valid query to Firestore
          FirebaseFirestore.instance.collection('good_queries').add({
            'type': typeIsMovie == 0 ? "movie" : "show",
            'timestamp': FieldValue.serverTimestamp(),
            'query': _controller.text,
          });

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecommandationResultsPage(requestString: _controller.text, type: typeIsMovie),
            ),
          );
        } else {
          FirebaseAnalytics.instance.logEvent(
            name: 'invalid_prompt',
            parameters: <String, Object>{
              "type": typeIsMovie == 0 ? "movie" : "show",
            },
          );

          // Log invalid query to Firestore
          FirebaseFirestore.instance.collection('invalid_queries').add({
            'type': typeIsMovie == 0 ? "movie" : "show",
            'timestamp': FieldValue.serverTimestamp(),
            'query': _controller.text,
          });

          showToastWidget(
            ToastWidget(
              title: "invalid_input".tr(),
              icon: const Icon(Icons.dangerous_outlined, color: Colors.red, size: 36),
            ),
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  void showExamples() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(11, 14, 23, 1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "need_inspiration".tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _exampleItem("example_1".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_2".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_3".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_4".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_5".tr(), Icons.auto_awesome_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showExamplesShows() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(11, 14, 23, 1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "need_inspiration".tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _exampleItem("example_show_1".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_show_2".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_show_3".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_show_4".tr(), Icons.auto_awesome_rounded),
                      _exampleItem("example_show_5".tr(), Icons.auto_awesome_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exampleItem(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
