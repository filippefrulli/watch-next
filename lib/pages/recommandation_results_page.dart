import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/objects/movie_credits.dart';
import 'package:watch_next/objects/streaming_service.dart';
import 'package:watch_next/objects/trailer.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/utils/secrets.dart';
import 'package:watch_next/widgets/movie_poster_widget.dart';
import 'package:http/http.dart' as http;

class RecommandationResultsPage extends StatefulWidget {
  final String requestString;
  final int type;

  const RecommandationResultsPage({Key? key, required this.requestString, required this.type}) : super(key: key);

  @override
  State<RecommandationResultsPage> createState() => _RecommandationResultsPageState();
}

class _RecommandationResultsPageState extends State<RecommandationResultsPage> {
  final openAI = OpenAI.instance
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), enableLog: true);

  late Future<dynamic> servicesList;

  int index = 0;
  int length = 0;
  bool askingGpt = false;
  bool fetchingMovieInfo = false;
  bool filtering = false;
  WatchObject selectedWatchObject = WatchObject();
  PanelController pc = PanelController();
  String responseItems = '';
  String itemsToNotRecommend = '';

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

    servicesList = HttpService().getWatchProvidersByLocale(http.Client());
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
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        ),
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            if (!filtering && !fetchingMovieInfo && !askingGpt) {
              return Column(children: [
                Text(
                  "here_recommendation".tr(),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  length != 0 ? '${index + 1} / $length' : '',
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
            if (!filtering && !fetchingMovieInfo && !askingGpt) {
              length = snapshot.data?.length ?? 0;
              selectedWatchObject = snapshot.data[index];
              return recommandationContent(selectedWatchObject);
            } else {
              return loadingWidget();
            }
          },
        ),
      ],
    );
  }

  Widget recommandationContent(WatchObject watchObject) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Expanded(
            flex: 20,
            child: recommandationsElementWidget(
              watchObject.posterPath ?? '/h5hVeCfYSb8gIO0F41gqidtb0AI.jpg',
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 5,
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
        IconButton(
          onPressed: () {
            setState(() {
              if (index == 0) {
              } else {
                index--;
              }
            });
            FirebaseAnalytics.instance.logEvent(
              name: 'moved_back',
            );
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
            setState(
              () {
                if (index == length - 1) {
                } else {
                  index++;
                }
              },
            );
            FirebaseAnalytics.instance.logEvent(
              name: 'moved_forward',
            );
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
              "watch_it_on".tr(),
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            streamingOption(),
          ],
        ),
        Expanded(
          child: Container(),
        ),
        Column(
          children: [
            infoButton(),
            index == length - 1 ? reloadButton() : Container(),
          ],
        ),
        Expanded(
          child: Container(),
        ),
      ],
    );
  }

  Widget reloadButton() {
    return TextButton(
      onPressed: () {
        FirebaseAnalytics.instance.logEvent(
          name: 'reloaded_recommendations',
          parameters: <String, dynamic>{
            "type": widget.type == 0 ? "movie" : "show",
          },
        );
        setState(() {
          index = 0;
          resultList.whenComplete(() => []);
          resultList = askGpt();
        });
      },
      child: Container(
        height: 42,
        width: 120,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
          color: Colors.orange,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: AutoSizeText(
                "new".tr(),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(
              width: 4,
            ),
            Icon(Icons.refresh, size: 32, color: Colors.grey[900]),
          ],
        ),
      ),
    );
  }

  Widget infoButton() {
    return TextButton(
      onPressed: () async {
        movieCredits = HttpService().fetchMovieCredits(http.Client(), selectedWatchObject.id!);
        if (widget.type == 0) {
          HttpService().fetchTrailer(http.Client(), selectedWatchObject.id!).then((value) {
            setState(() {
              trailerList = value;
            });

            waitForImages();
          });
        } else {
          HttpService().fetchTrailerSeries(http.Client(), selectedWatchObject.id!).then((value) {
            setState(() {
              trailerList = value;
            });

            waitForImages();
          });
        }
        FirebaseAnalytics.instance.logEvent(
          name: 'opened_info',
          parameters: <String, dynamic>{
            "type": widget.type == 0 ? "movie" : "show",
          },
        );
        pc.open();
      },
      child: Container(
        height: 42,
        width: 120,
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
    );
  }

  Widget streamingOption() {
    if (selectedWatchObject.watchProviders != null) {
      if (selectedWatchObject.watchProviders?.first == null) {
        return Container();
      } else {
        return FutureBuilder(
          future: servicesList,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DelayedDisplay(
                  delay: const Duration(milliseconds: 1000),
                  child: SizedBox(
                    height: 64,
                    width: 64,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: streamingLogo(
                          snapshot.data,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Expanded(
                child: Container(),
              );
            }
          },
        );
      }
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
              prefs.setInt('accepted_movie', selectedWatchObject.id!);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              "accept".tr(),
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
              height: 46,
            ),
            askingGpt
                ? Text(
                    "generating".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
            fetchingMovieInfo
                ? Text(
                    "fetching".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
            filtering
                ? Text(
                    "filtering".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
            const SizedBox(
              height: 46,
            ),
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
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Text(
                  selectedWatchObject.title ?? '',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            selectedWatchObject.overview ?? '',
            maxLines: 17,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "tmdb_score".tr() + (selectedWatchObject.tmdbRating?.toStringAsFixed(1) ?? ''),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey[800]),
          const SizedBox(height: 8),
          trailerWidget(),
        ],
      ),
    ));
  }

  Widget trailerWidget() {
    if (trailerList.isNotEmpty && trailerImages.isNotEmpty) {
      return DelayedDisplay(
        child: SizedBox(
          height: 142,
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
                  width: 150,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        height: 86,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 21 / 9,
                            child: CachedNetworkImage(
                              imageUrl: thumbnail,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
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

  Widget streamingLogo(List<StreamingService> streamingList) {
    for (StreamingService item in streamingList) {
      if (item.providerId == selectedWatchObject.watchProviders!.first) {
        return CachedNetworkImage(
          fit: BoxFit.fill,
          imageUrl: "http://image.tmdb.org/t/p/original//${item.logoPath}",
          placeholder: (context, url) => Container(
            color: const Color.fromRGBO(11, 14, 23, 1),
          ),
          errorWidget: (context, url, error) => Expanded(
            child: Container(
              color: Colors.grey[800],
            ),
          ),
        );
      }
    }
    return Container();
  }

  Future<dynamic> askGpt() async {
    setState(() {
      askingGpt = true;
    });

    String doNotRecomment = itemsToNotRecommend.isNotEmpty ? 'do_not_recommend'.tr() + itemsToNotRecommend : '';

    String queryContent = widget.type == 0
        ? 'prompt_1'.tr() + ' ' + widget.requestString + '. ' + 'prompt_2'.tr() + ' ' + doNotRecomment
        : 'prompt_series_1'.tr() + ' ' + widget.requestString + '. ' + 'prompt_series_2'.tr() + ' ' + doNotRecomment;
    final request = ChatCompleteText(
      messages: [
        Messages(
          role: Role.assistant,
          content: queryContent,
        ),
      ],
      temperature: 0.6,
      maxToken: 400,
      model: GptTurboChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);
    itemsToNotRecommend = '';

    setState(() {
      askingGpt = false;
      itemsToNotRecommend = response!.choices[0].message!.content;
    });

    return parseResponse(response!.choices[0].message!.content).then(
      (value) => filterProviders(value),
    );
  }

  parseResponse(String response) async {
    setState(() {
      fetchingMovieInfo = true;
    });

    List<WatchObject> watchObjectsList = [];

    List<String> responseTitles = response.split(',,');
    if (responseTitles.isEmpty) {
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: "prompt_issue".tr(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    for (String movieTitle in responseTitles) {
      List<String> list = movieTitle.split('y:');
      if (list.length > 1) {
        if (widget.type == 0) {
          await HttpService().findMovieByTitle(http.Client(), list[0], list[1]).then(
            (movieResult) {
              if (movieResult.id != null) {
                watchObjectsList.add(
                  WatchObject(
                    posterPath: movieResult.posterPath,
                    overview: movieResult.overview,
                    tmdbRating: movieResult.voteAverage,
                    id: movieResult.id,
                    title: movieResult.title,
                  ),
                );
              }
            },
          );
        } else {
          await HttpService().findShowByTitle(http.Client(), list[0], list[1]).then(
            (seriesResult) {
              if (seriesResult.id != null) {
                watchObjectsList.add(
                  WatchObject(
                    posterPath: seriesResult.posterPath,
                    overview: seriesResult.overview,
                    tmdbRating: seriesResult.voteAverage,
                    id: seriesResult.id,
                    title: seriesResult.title,
                  ),
                );
              }
            },
          );
        }
      } else {}
    }

    setState(() {
      fetchingMovieInfo = false;
    });

    return watchObjectsList;
  }

  filterProviders(List<WatchObject> watchObjectList) async {
    setState(() {
      filtering = true;
    });

    Map<int, WatchObject> watchObjectMap = {};
    for (WatchObject watchObject in List<WatchObject>.from(watchObjectList)) {
      if (widget.type == 0) {
        await HttpService()
            .getWatchProviders(
              http.Client(),
              watchObject.id!,
            )
            .then(
              (value) => {
                if (value.isNotEmpty)
                  {
                    watchObject.watchProviders = value,
                    watchObjectMap[watchObject.id!] = watchObject,
                  }
              },
            );
      } else {
        await HttpService()
            .getWatchProvidersSeries(
              http.Client(),
              watchObject.id!,
            )
            .then(
              (value) => {
                if (value.isNotEmpty)
                  {
                    watchObject.watchProviders = value,
                    watchObjectMap[watchObject.id!] = watchObject,
                  }
              },
            );
      }
    }
    setState(() {
      filtering = false;
    });
    if (watchObjectMap.values.toList().isEmpty && mounted) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
          msg: "no_movies".tr(),
          timeInSecForIosWeb: 4,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      return watchObjectMap.values.toList();
    }
  }

  String getDirector(MovieCredits credits) {
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

class WatchObject {
  String? posterPath;
  String? overview;
  double? tmdbRating;
  int? id;
  String? title;
  List<int>? watchProviders;

  WatchObject({
    this.posterPath,
    this.overview,
    this.tmdbRating,
    this.id,
    this.title,
    this.watchProviders,
  });
}
