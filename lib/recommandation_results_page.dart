import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/objects/movie_details.dart';
import 'secrets.dart';
import 'services/http_service.dart';
import 'package:http/http.dart' as http;

class RecommandationResultsPage extends StatefulWidget {
  final String requestString;
  const RecommandationResultsPage({Key? key, required this.requestString}) : super(key: key);

  @override
  State<RecommandationResultsPage> createState() => _RecommandationResultsPageState();
}

class _RecommandationResultsPageState extends State<RecommandationResultsPage> {
  final openAI = OpenAI.instance
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), isLog: true);

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
    final request = ChatCompleteText(
      messages: [
        Map.of({
          "role": "user",
          "content": 'Return 10 titles (in the format title,title,etc on one line) of movies ${widget.requestString}'
        }),
      ],
      maxToken: 200,
      model: kChatGptTurbo0301Model,
    );

    final response = await openAI.onChatCompletion(request: request);
    parseResponse(response!.choices[0].message.content);
  }

  Future<List<MovieDetails>> parseResponse(String response) async {
    List<MovieDetails> movieList = [];
    List<String> responseMovies = response.split(',');
    for (String movie in responseMovies) {
      await HttpService()
          .findMovieByTitle(http.Client(), movie)
          .then(
            (value) => HttpService().fetchMovieDetails(http.Client(), value.id!),
          )
          .then(
            (value) => movieList.add(value),
          );
    }
    List<int> providers = [];
    for (MovieDetails movie in movieList) {
      providers.add(await HttpService().getWatchProviders(http.Client(), movie.id!));
    }
    for (int x = 0; x < movieList.length; x++) {
      if (providers[x] == 0) {
        movieList.removeAt(x);
      }
    }
    print("RECOMMENDIG ${movieList.length} MOVIES");
    return movieList;
  }

  // List<MovieDetails> filterWatchProviders(List<MovieDetails> list) {
  //   for (MovieDetails item in list) {
  //     if (item. == null) {
  //       list.remove(item);
  //     }
  //   }
  //   return [];
  // }
}
