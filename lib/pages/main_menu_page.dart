import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:watch_next/pages/recommandation_results_page.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/widgets/toast_widget.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({Key? key}) : super(key: key);

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

int currentIndex = -1;

final openAI = OpenAI.instance
    .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), enableLog: true);

final _controller = TextEditingController();

bool isLongEnough = false;
bool isValidQuery = false;
bool enableLoading = false;
bool hideExample = false;

class _MainMenuPageState extends State<MainMenuPage> {
  bool noInternet = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(checkLength);
    _controller.text = ' ';
    hideExample = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
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
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: topBar(),
            ),
            Expanded(
              flex: 2,
              child: Container(),
            ),
            Expanded(
              flex: 1,
              child: description(),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: promptInput(),
            ),
            const SizedBox(height: 16),
            hideExample
                ? Container()
                : Expanded(
                    flex: 4,
                    child: promptExample(),
                  ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Expanded(
              flex: 2,
              child: goButton(),
            ),
            const SizedBox(height: 16),
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
            "Hey There!",
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
      },
    );
  }

  Widget description() {
    return Text(
      "Find something to watch next",
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayMedium,
    );
  }

  Widget promptInput() {
    return TextField(
      autofocus: false,
      maxLength: 60,
      showCursor: true,
      controller: _controller,
      cursorColor: Colors.orange,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromRGBO(35, 35, 50, 1),
        helperText: 'Complete the sentence (at least 6 characters)',
        prefixText: "Recommend a movie... ",
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
    );
  }

  Widget promptExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '• that is romantic and funny, ideal for a first date',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '• starring Tom Cruise and directed by Steven Spielberg',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '• about artificial intelligence, with good reviews',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(0),
            ),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              await checkConnection();
              if (noInternet) {
                showToastWidget(
                  const ToastWidget(
                    title: ('Please connect to the internet and try again'),
                    icon: Icon(Icons.cloud_off, color: Colors.orange, size: 36),
                  ),
                  duration: const Duration(seconds: 4),
                );
              } else {
                if (isLongEnough && mounted) {
                  setState(() {
                    enableLoading = true;
                  });
                  await validateQuery();
                  if (isValidQuery && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecommandationResultsPage(requestString: _controller.text),
                      ),
                    );
                  } else {
                    showToastWidget(
                      const ToastWidget(
                        title: ('Inalid input, please change your query and try again'),
                        icon: Icon(Icons.dangerous_outlined, color: Colors.red, size: 36),
                      ),
                      duration: const Duration(seconds: 4),
                    );
                  }
                }
              }
            },
            child: Container(
              height: 60,
              width: 180,
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
                        "GO",
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
    if (_controller.text.isNotEmpty && mounted) {
      setState(() {
        hideExample = true;
      });
    }
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
    if (_controller.text.isEmpty && mounted) {
      setState(() {
        hideExample = false;
      });
    }
  }

  validateQuery() async {
    final request = ChatCompleteText(
      messages: [
        Messages(
            role: Role.assistant,
            content:
                'Your job is to validate wether a given sentence is a request to recommend a movie. Examples of correct prompts are: "Recommend a movie that is romantic and funny, ideal for a first date", "Recommend a movie starring Tom Cruise and directed by Steven Spielberg", "Recommend a movie about artificial intelligence, with good reviews". If the prompt is valid, return just the text YES, otherwise NO. The prompt is: Recommend a movie ${_controller.text}'),
      ],
      maxToken: 200,
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
}
