import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/movie_details.dart';
import 'package:watch_next/objects/trailer.dart';
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
  bool askingGpt = false;
  bool fetchingMovieInfo = false;
  bool filtering = false;
  MovieDetails selectedMovie = MovieDetails();
  PanelController pc = PanelController();

  late Future<dynamic> resultList;
  Future<MovieCredits> movieCredits = Future.value(MovieCredits());

  String? trailerUrl = '';
  String? title = '';

  List<TrailerResults> trailerList = [];
  List<String> trailerImages = [];

  String thumbnail = "https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg";
  String baseUrl = 'https://www.youtube.com/watch?v=';

  @override
  initState() {
    super.initState();
    resultList = askGpt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: SlidingUpPanel(
        controller: pc,
        margin: const EdgeInsets.all(8.0),
        panel: movieInfoPanel(),
        borderRadius: const BorderRadius.all(
          Radius.circular(25),
        ),
        collapsed: Container(),
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height * 0.80,
        backdropEnabled: true,
        backdropOpacity: 0.8,
        color: Theme.of(context).primaryColor,
        body: pageBody(),
      ),
    );
  }

  Widget pageBody() {
    return Column(
      children: [
        const SizedBox(
          height: 32,
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
      height: MediaQuery.of(context).size.height * 0.88,
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
            flex: 4,
            child: streamingWidget(),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 3,
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
    return Row(
      children: [
        Expanded(
          child: Container(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Watch it on:',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            streamingOption(),
          ],
        ),
        Expanded(
          child: Container(),
        ),
        TextButton(
          onPressed: () async {
            movieCredits = HttpService().fetchMovieCredits(http.Client(), selectedMovie.id!);
            HttpService().fetchTrailer(http.Client(), selectedMovie.id!).then((value) {
              setState(() {
                trailerList = value;
              });

              waitForImages();
            });
            pc.open();
          },
          child: Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(15),
              ),
              color: Colors.grey[800],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Info",
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(
                  width: 8,
                ),
                const Icon(Icons.expand_less, size: 32, color: Colors.white),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(),
        ),
      ],
    );
  }

  Widget streamingOption() {
    if (selectedMovie.watchProviders != null) {
      return DelayedDisplay(
        delay: const Duration(milliseconds: 1000),
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 50,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[300],
          ),
          child: Platform.isIOS
              ? Image.asset(providersMapIos[selectedMovie.watchProviders!.first]!)
              : Image.asset(providersMap[selectedMovie.watchProviders!.first]!),
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
          height: 50,
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

  Widget loadingWidget() {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.threeArchedCircle(
              color: Colors.orange,
              size: 50,
            ),
            const SizedBox(
              height: 16,
            ),
            askingGpt
                ? Text(
                    "Generating recommendations",
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
            fetchingMovieInfo
                ? Text(
                    "Fetching movie information",
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
            filtering
                ? Text(
                    "Filtering by your services",
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget movieInfoPanel() {
    return DelayedDisplay(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(width: 50, height: 5, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container()),
                Text(
                  selectedMovie.title ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Expanded(child: Container()),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(selectedMovie.overview ?? '', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey[800]),
            const SizedBox(height: 16),
            FutureBuilder<dynamic>(
              future: movieCredits,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    "Director: ${getDirector(snapshot.data)}",
                    style: Theme.of(context).textTheme.displaySmall,
                  );
                } else {
                  return Container();
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              "TMDB score: ${selectedMovie.voteAverage?.toStringAsFixed(1) ?? ''}",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              "Trailers:",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            trailerWidget(),
          ],
        ),
      ),
    );
  }

  Widget trailerWidget() {
    if (trailerList.isNotEmpty && trailerImages.isNotEmpty) {
      return DelayedDisplay(
        child: SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trailerList.length,
            itemBuilder: (context, index) {
              trailerUrl = trailerList[index].key;
              title = trailerList[index].name;
              thumbnail = trailerImages[index];
              return TextButton(
                onPressed: () => _launchURL(trailerUrl!),
                child: SizedBox(
                  height: 158,
                  width: 160,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 124,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(imageUrl: thumbnail),
                        ),
                      ),
                      Text(
                        title!,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<dynamic> askGpt() async {
    setState(() {
      askingGpt = true;
    });
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

    setState(() {
      askingGpt = false;
    });

    return parseResponse(response!.choices[0].message!.content).then(
      (value) => filterProviders(value),
    );
  }

  parseResponse(String response) async {
    setState(() {
      fetchingMovieInfo = true;
    });
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

    setState(() {
      fetchingMovieInfo = false;
    });

    return movieList;
  }

  filterProviders(List<MovieDetails> movieList) async {
    setState(() {
      filtering = true;
    });

    Map<int, MovieDetails> movieMap = {};
    for (MovieDetails movie in List<MovieDetails>.from(movieList)) {
      await HttpService()
          .getWatchProviders(
            http.Client(),
            movie.id!,
          )
          .then(
            (value) => {
              if (value.isNotEmpty)
                {
                  movie.watchProviders = value,
                  movieMap[movie.id!] = movie,
                }
            },
          );
    }
    setState(() {
      filtering = false;
    });
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

  String getDirector(MovieCredits credits) {
    ///this retrieves the first director of the movie
    List<Crew>? list = credits.crew;
    int index;
    if (list == null) {
      return "";
    }
    index = list.indexWhere((crew) => crew.job == "Director");

    return list[index].name!;
  }

  _launchURL(String trailerUrl) async {
    Uri uri = Uri.parse(baseUrl + trailerUrl);
    if (Platform.isIOS) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw 'Could not launch trailer';
        }
      }
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri';
      }
    }
  }

  getTrailerImages() async {
    trailerImages = [];
    for (int i = 0; i < trailerList.length; i++) {
      var jsonData = await HttpService().getDetail(baseUrl + trailerList[i].key!);
      if (jsonData != null) {
        String thumbnail = jsonData['thumbnail_url'];
        trailerImages.add(thumbnail);
      } else {
        trailerImages.add('https://i.ytimg.com//vi//d_m5csmrf7I//hqdefault.jpg');
      }
    }
  }

  waitForImages() async {
    await getTrailerImages();
    setState(() {});
  }
}
