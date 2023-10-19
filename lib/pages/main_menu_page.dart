import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:watch_next/pages/recommandation_results_page.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/widgets/toast_widget.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({Key? key}) : super(key: key);

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int currentIndex = -1;

  final openAI = OpenAI.instance
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), enableLog: true);

  final _controller = TextEditingController();

  bool isLongEnough = false;
  bool isValidQuery = false;
  bool enableLoading = false;
  bool hideExample = false;

  GlobalKey textFieldKey = GlobalKey();
  GlobalKey goButtonKey = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  bool noInternet = false;
  int typeIsMovie = 0; //0 = movie 1 = show

  @override
  void initState() {
    createTutorial();
    super.initState();
    _controller.addListener(checkLength);
    _controller.text = '';
    hideExample = false;
    Timer(const Duration(seconds: 2), () {
      showTutorial();
    });
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
            const SizedBox(height: 16),
            topBar(),
            Expanded(
              flex: 2,
              child: Container(),
            ),
            description(),
            const SizedBox(height: 32),
            switchWidget(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.orange,
                  size: 26,
                ),
                onPressed: () {
                  FirebaseAnalytics.instance.logEvent(
                    name: 'opened_examples',
                    parameters: <String, dynamic>{
                      "type": typeIsMovie == 0 ? "movie" : "show",
                    },
                  );
                  typeIsMovie == 0 ? showExamples() : showExamplesShows();
                },
              ),
            ),
            const SizedBox(height: 2),
            promptInput(),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Container(),
            ),
            goButton(),
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
    return IconButton(
      icon: Icon(
        Icons.settings,
        color: Colors.grey[400],
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
    return SizedBox(
      height: 80,
      child: TextField(
        key: textFieldKey,
        autofocus: false,
        maxLength: 60,
        showCursor: true,
        maxLines: 1,
        minLines: 1,
        controller: _controller,
        cursorColor: Colors.orange,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromRGBO(35, 35, 50, 1),
          helperText: "complete_sentence".tr(),
          hintText: typeIsMovie == 0 ? "recommend_a_movie".tr() : "recommend_a_show".tr(),
          prefixStyle: Theme.of(context).textTheme.displaySmall!.copyWith(fontSize: 12),
          suffixText: "",
          helperStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.only(left: 14.0, bottom: 10.0, top: 10.0),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2.0),
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2.0),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget goButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          TextButton(
            key: goButtonKey,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(0),
            ),
            onPressed: () async {
              goButtonPressed();
            },
            child: Container(
              height: 50,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(25),
                ),
                color: isLongEnough ? Colors.orange : Colors.grey,
              ),
              child: Center(
                child: enableLoading
                    ? LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.grey[900]!,
                        size: 30,
                      )
                    : Text(
                        "go".tr(),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[900],
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    );
  }

  void checkLength() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.text.length > 5 && mounted) {
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

  validateQuery() async {
    final request = ChatCompleteText(
      messages: [
        Messages(
            role: Role.assistant,
            content: typeIsMovie == 0
                ? 'validation_prompt'.tr() + _controller.text
                : 'validation_prompt_series'.tr() + _controller.text),
      ],
      maxToken: 400,
      model: GptTurbo0301ChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);
    if (response!.choices[0].message!.content == "YES" && mounted) {
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

  void showTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int showed = prefs.getInt('showed_tutorial') ?? 0;
    if (showed == 0 && mounted) {
      tutorialCoachMark.show(context: context);
    }
    prefs.setInt("showed_tutorial", 1);
  }

  void createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.grey[900]!,
      textSkip: "close".tr(),
      paddingFocus: 10,
      opacityShadow: 0.5,
      focusAnimationDuration: const Duration(seconds: 2),
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onClickTarget: (target) {
        if (target.keyTarget == textFieldKey) {
          setState(() {
            _controller.text = "with_action".tr();
          });
        } else {
          goButtonPressed();
        }
      },
      onClickOverlay: (target) {
        setState(
          () {
            _controller.text = "with_action".tr();
          },
        );
      },
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        shape: ShapeLightFocus.RRect,
        identify: "textFieldKey",
        keyTarget: textFieldKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "step_one".tr(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              );
            },
          ),
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "try_with_action".tr(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  Text(
                    "tap_text_field".tr(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "goButtonKey",
        keyTarget: goButtonKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "step_two".tr(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  void goButtonPressed() async {
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
            name: 'go_button_pressed',
            parameters: <String, dynamic>{
              "type": typeIsMovie == 0 ? "movie" : "show",
              "prompt": _controller.text,
            },
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecommandationResultsPage(requestString: _controller.text, type: typeIsMovie),
            ),
          );
        } else {
          FirebaseAnalytics.instance.logEvent(
            name: 'invalid_prompt',
            parameters: <String, dynamic>{
              "prompt": _controller.text,
              "type": typeIsMovie == 0 ? "movie" : "show",
            },
          );
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
        title: Text("need_inspiration".tr()),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "example_1".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_2".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_3".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_4".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_5".tr(),
              style: Theme.of(context).textTheme.displaySmall,
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
