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
      children: [
        const SizedBox(
          width: 48,
        ),
        Expanded(
          child: Container(),
        ),
        DelayedDisplay(
          fadingDuration: const Duration(milliseconds: 1000),
          child: Text(
            "hey_there".tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Container(),
        ),
        settingsButton(),
      ],
    );
  }

  Widget settingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        icon: Icon(
          Icons.settings,
          color: Colors.grey[900],
          size: 28,
        ),
        onPressed: () {
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
    return ToggleSwitch(
      minWidth: 110.0,
      initialLabelIndex: typeIsMovie,
      cornerRadius: 15.0,
      animate: true,
      animationDuration: 400,
      activeFgColor: Colors.white,
      inactiveBgColor: Colors.grey[900],
      inactiveFgColor: Colors.white,
      totalSwitches: 2,
      labels: ['movie'.tr(), 'tv_show'.tr()],
      activeBgColors: const [
        [Colors.orange],
        [Colors.orange],
      ],
      onToggle: (index) {
        setState(() {
          typeIsMovie = index!;
        });
      },
    );
  }

  Widget description() {
    return Text(
      "find_something".tr(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayMedium,
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
      builder: (_) => AlertDialog(
        shape: ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          1,
        )!,
        backgroundColor: Colors.grey[900]!,
        title: Text(
          "need_inspiration".tr(),
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 20,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "example_1".tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_2".tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_3".tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_4".tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_5".tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  void showExamplesShows() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          1,
        )!,
        backgroundColor: Colors.grey[900]!,
        title: Text("need_inspiration".tr()),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "example_show_1".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_show_2".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_show_3".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_show_4".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_show_5".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }
}
