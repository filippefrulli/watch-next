import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:watch_next/pages/recommandation_results_page.dart';
import 'package:watch_next/pages/settings_page.dart';
import 'package:watch_next/utils/secrets.dart';

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
bool enableWrongQuery = false;

class _MainMenuPageState extends State<MainMenuPage> {
  final Map<int, String> availableCategories = {
    0: 'Lean back and relax',
    1: 'Quality cinema',
    2: 'Action packed',
    3: 'Romantic date',
    4: 'For children',
    5: 'Horror night',
    6: 'Anything',
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(checkLength);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.renderView.automaticSystemUiAdjustment = false;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: body(),
    );
  }

  Widget body() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 48),
            topBar(),
            const SizedBox(
              height: 120,
            ),
            description(),
            const SizedBox(height: 32),
            promptInput(),
            const SizedBox(height: 32),
            promptExample(),
            const SizedBox(height: 32),
            goButton(),
            const SizedBox(height: 32),
            enableWrongQuery ? invalidPrompt() : Container(),
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
      "To get your recommandation, fill out the prompt",
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displaySmall,
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
        hintText: 'Recommend a movie...',
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 18, fontStyle: FontStyle.italic),
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
      onSubmitted: (String value) async {},
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

  Widget lastSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last searches:',
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
              if (isLongEnough) {
                setState(() {
                  enableLoading = true;
                });
                await validateQuery();
                if (isValidQuery) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecommandationResultsPage(requestString: _controller.text),
                    ),
                  );
                }
              } else {}
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

  Widget invalidPrompt() {
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color.fromRGBO(35, 35, 50, 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.dangerous_outlined, color: Colors.red, size: 40),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              "Invalid prompt.\n\nPlease change your query and try again",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ],
      ),
    );
  }

  void checkLength() {
    if (_controller.text.length > 5) {
      setState(() {
        isLongEnough = true;
      });
    }
    if (_controller.text.length < 5 && isLongEnough) {
      setState(() {
        isLongEnough = false;
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
      model: GptTurbo0631Model(),
    );

    final response = await openAI.onChatCompletion(request: request);
    if (response!.choices[0].message!.content == "YES") {
      setState(() {
        isValidQuery = true;
        enableLoading = false;
        enableWrongQuery = false;
      });
    } else {
      setState(() {
        isValidQuery = false;
        enableLoading = false;
        enableWrongQuery = true;
      });
    }
  }
}
