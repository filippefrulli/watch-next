import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/movie_details.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/utils/constants.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/widgets/movie_poster_widget.dart';
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

  int index = 0;
  int length = 0;
  MovieDetails selectedMovie = MovieDetails();

  Map<int, String> streamingServices = {
    8: 'Netflix',
    9: 'Amazon Prime Video',
    350: 'Disney+',
    337: 'HBO Max',
    384: 'Hulu',
    15: 'Apple TV+',
    531: 'Peacock',
    386: 'Paramount+',
  };

  late Future<dynamic> resultList;

  @override
  initState() {
    super.initState();
    resultList = askGpt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: pageBody(),
    );
  }

  Widget pageBody() {
    return Column(
      children: [
        const SizedBox(
          height: 48,
        ),
        Text(
          'Here is our recommendation',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(
          height: 8,
        ),
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              return Text(
                length != 0 ? '${index + 1} of $length' : '',
                style: Theme.of(context).textTheme.bodySmall,
              );
            } else {
              return Expanded(
                child: Container(),
              );
            }
          },
        ),
        const SizedBox(
          height: 16,
        ),
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              length = snapshot.data.length;
              selectedMovie = snapshot.data[index];
              return recommandationContent(selectedMovie);
            } else {
              return loadingWidget();
            }
          },
        ),
      ],
    );
  }

  Widget recommandationContent(MovieDetails selectedMovie) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Expanded(
            flex: 16,
            child: recommandationsElementWidget(
              selectedMovie.posterPath ?? '/h5hVeCfYSb8gIO0F41gqidtb0AI.jpg',
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 3,
            child: streamingWidget(),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 2,
            child: buttonsRow(),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget buttonsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(),
        ),
        acceptButton(),
        Expanded(
          child: Container(),
        ),
        notInterestedButton(),
        Expanded(
          child: Container(),
        ),
      ],
    );
  }

  Widget streamingWidget() {
    return Align(
      alignment: Alignment.centerLeft,
      child: DelayedDisplay(
        delay: const Duration(milliseconds: 1000),
        child: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Watch it on:',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              streamingOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget streamingOptions() {
    if (selectedMovie.watchProviders != null) {
      return DelayedDisplay(
        delay: const Duration(milliseconds: 1000),
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 50,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[300],
          ),
          child: Image.asset(providersMap[selectedMovie.watchProviders!.first]!),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget recommandationsElementWidget(String poster) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(25),
      ),
      child: MoviePosterWidget(
        poster: poster,
      ),
    );
  }

  Widget acceptButton() {
    return Center(
      child: DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          width: 150,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(25),
            ),
            color: Colors.orange,
          ),
          child: TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setInt('accepted_movie', selectedMovie.id!);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'Accept',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget notInterestedButton() {
    return Center(
      child: DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          width: 150,
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(25),
              ),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              )),
          child: TextButton(
            onPressed: () {
              DatabaseService.insertNotInterested(selectedMovie.id!);
              setState(() {
                if (index < length - 1) {
                  index++;
                }
              });
            },
            child: Text(
              'Not interested',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ),
      ),
    );
  }

  Widget loadingWidget() {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Generating your suggestions",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(
              height: 32,
            ),
            LoadingAnimationWidget.threeArchedCircle(
              color: Colors.orange,
              size: 50,
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> askGpt() async {
    final request = ChatCompleteText(
      messages: [
        Map.of({
          "role": "user",
          "content":
              'Return 20 titles (in the format "title y:release date",, with double commas on one line and not as anumbered list!) of movies ${widget.requestString}. Here is an example response: star wars y:1977,, Jurassic Park y:1993. Do not number the response elements! '
        }),
      ],
      maxToken: 200,
      model: kChatGptTurbo0301Model,
    );

    final response = await openAI.onChatCompletion(request: request);
    return parseResponse(response!.choices[0].message.content).then(
      (value) => filterProviders(value),
    );
  }

  parseResponse(String response) async {
    List<MovieDetails> movieList = [];
    List<String> responseMovies = response.split(',,');
    for (String movieTitle in responseMovies) {
      List<String> list = movieTitle.split('y:');
      if (list.length > 1) {
        await HttpService().findMovieByTitle(http.Client(), list[0], list[1]).then(
          (movieResult) {
            if (movieResult.id != null) {
              HttpService().fetchMovieDetails(http.Client(), movieResult.id!).then((movieDetail) {
                movieList.add(movieDetail);
              });
            }
          },
        );
      } else {}
    }
    return movieList;
  }

  filterProviders(List<MovieDetails> movieList) async {
    Map<int, MovieDetails> movieMap = {};
    for (MovieDetails movie in List<MovieDetails>.from(movieList)) {
      await HttpService().getWatchProviders(http.Client(), movie.id!).then((value) => {
            if (value.isNotEmpty)
              {
                movie.watchProviders = value,
                movieMap[movie.id!] = movie,
              }
          });
    }
    return movieMap.values.toList();
  }
}
