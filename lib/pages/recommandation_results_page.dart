import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), enableLog: true);

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
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              return Column(children: [
                Text(
                  'Here is our recommendation',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  length != 0 ? '${index + 1} of $length' : '',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              ]);
            } else {
              return Expanded(
                child: Container(),
              );
            }
          },
        ),
        const SizedBox(
          height: 8,
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
            flex: 20,
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
            flex: 2,
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
        IconButton(
          onPressed: () {
            setState(() {
              if (index == 0) {
              } else {
                index--;
              }
            });
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 32,
            color: index == 0 ? Colors.grey[600] : Colors.white,
          ),
        ),
        Expanded(
          child: Container(),
        ),
        acceptButton(),
        Expanded(
          child: Container(),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              if (index == length - 1) {
              } else {
                index++;
              }
            });
          },
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 32,
            color: index == length - 1 ? Colors.grey[600] : Colors.white,
          ),
        ),
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
          height: 46,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[300],
          ),
          child: Platform.isIOS
              ? Image.asset(providersMap[selectedMovie.watchProviders!.first]!)
              : Image.asset(providersMapIos[selectedMovie.watchProviders!.first]!),
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
        Messages(
            role: Role.assistant,
            content:
                'Return 30 titles (in the format "title y:release date",, with double commas on one line and not as anumbered list!) of movies ${widget.requestString}. Here is an example response: star wars y:1977,, Jurassic Park y:1993. Do not number the response elements! Do not recommend more than one movie from the same franchise! '),
      ],
      maxToken: 200,
      model: GptTurbo0301ChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);
    return parseResponse(response!.choices[0].message!.content).then(
      (value) => filterProviders(value),
    );
  }

  parseResponse(String response) async {
    List<MovieDetails> movieList = [];
    List<String> responseMovies = response.split(',,');
    if (responseMovies.isEmpty) {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "We had an issue with your promt. Please try again",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
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
    if (movieMap.values.toList().isEmpty) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
          msg: "We couldn't find any movies on your streaming services. Please try again",
          timeInSecForIosWeb: 4,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      return movieMap.values.toList();
    }
  }
}
