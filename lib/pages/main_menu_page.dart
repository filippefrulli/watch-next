import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
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

  GlobalKey textFieldKey = GlobalKey();
  GlobalKey goButtonKey = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  bool noInternet = false;
  int typeIsMovie = 0; //0 = movie , 1 = show

  @override
  void initState() {
    createTutorial();
    super.initState();
    _controller.addListener(checkLength);
    _controller.text = ' ';
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
              parameters: <String, dynamic>{
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
          width: 305,
          child: TextField(
            key: textFieldKey,
            autofocus: false,
            showCursor: true,
            maxLength: 80,
            maxLines: 3,
            minLines: 1,
            controller: _controller,
            cursorColor: Colors.orange,
            style: Theme.of(context).textTheme.titleMedium,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromARGB(255, 44, 46, 56),
              helperText: "complete_sentence".tr(),
              prefixText: typeIsMovie == 0 ? "recommend_a_movie".tr() : "recommend_a_show".tr(),
              prefixStyle: Theme.of(context).textTheme.displaySmall!.copyWith(fontSize: 12, letterSpacing: 0.5),
              helperStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
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
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: isLongEnough ? Colors.orange : Colors.grey[700],
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: IconButton(
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
    FirebaseAnalytics.instance.logEvent(
      name: 'go_button_pressed',
      parameters: <String, dynamic>{
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
            parameters: <String, dynamic>{
              "type": typeIsMovie == 0 ? "movie" : "show",
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
