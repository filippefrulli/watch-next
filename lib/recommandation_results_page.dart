import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'secrets.dart';

class RecommandationResultsPage extends StatefulWidget {
  const RecommandationResultsPage({Key? key}) : super(key: key);

  @override
  State<RecommandationResultsPage> createState() => _RecommandationResultsPageState();
}

class _RecommandationResultsPageState extends State<RecommandationResultsPage> {
  final openAI = OpenAI.instance
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)), isLog: true);

  @override
  initState() {
    super.initState();
    askGpt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: pageBody(),
      ),
    );
  }

  Widget pageBody() {
    return const Center(
      child: Text('here is your results'),
    );
  }

  void askGpt() async {
    final request = ChatCompleteText(messages: [
      Map.of({"role": "user", "content": 'Recommend me a movie'}),
    ], maxToken: 200, model: kChatGptTurbo0301Model);

    final response = await openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      print("data -> ${element.message.content}");
    }
  }
}
