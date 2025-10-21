import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/main_menu_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';

///This is the page where you enter the movie you saw
class StreamingServicesPage extends StatefulWidget {
  const StreamingServicesPage({
    super.key,
  });
  @override
  State<StreamingServicesPage> createState() => _StreamingServicesPage();
}

class _StreamingServicesPage extends State<StreamingServicesPage> with TickerProviderStateMixin {
  late Future<dynamic> resultList;

  Map<int, String> selectedStreamingServices = {};

  @override
  void initState() {
    resultList = HttpService().getWatchProvidersByLocale();
    DatabaseService.getAllStreamingServices().then(
      (mapList) => {
        for (var map in mapList)
          {
            selectedStreamingServices[int.parse(map['streaming_id'].toString())] = map['streaming_logo'].toString(),
          },
        setState(
          () {},
        )
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: body(),
    );
  }

  Widget body() {
    return Column(
      children: [
        const SizedBox(height: 48),
        Text(
          "select_streaming".tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 32),
        streamingGrid(),
        Expanded(
          child: Container(),
        ),
        closeButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget streamingGrid() {
    return FutureBuilder<dynamic>(
      future: resultList,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data.length > 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(
                  color: Colors.grey[700]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
              height: MediaQuery.of(context).size.height * 0.7,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                ),
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(0),
                      ),
                      onPressed: () {
                        setState(() {
                          if (selectedStreamingServices.containsKey(snapshot.data[index].providerId)) {
                            selectedStreamingServices
                                .removeWhere((key, value) => key == snapshot.data[index].providerId);
                          } else {
                            selectedStreamingServices[snapshot.data[index].providerId] = snapshot.data[index].logoPath;
                          }
                        });
                      },
                      child: gridItem(snapshot.data[index].logoPath, index, snapshot.data[index].providerId),
                    ),
                  );
                },
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

  Widget closeButton() {
    return selectedStreamingServices.isNotEmpty
        ? SizedBox(
            height: 50,
            child: Center(
              child: TextButton(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  bool seen = prefs.getBool('skip_intro') ?? false;
                  prefs.setBool('skip_intro', true);
                  await DatabaseService.saveStreamingServices(selectedStreamingServices);
                  if (mounted && seen) {
                    Navigator.of(context).pop();
                  } else if (mounted && !seen) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainMenuPage(),
                      ),
                    );
                  }
                },
                child: Text(
                  "done".tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        : Container();
  }

  Widget gridItem(String logo, int index, int providerId) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
          width: 3,
          color: selectedStreamingServices.keys.contains(providerId) ? Colors.orange : Colors.white,
        ),
        color: Colors.grey[300],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: "https://image.tmdb.org/t/p/original//$logo",
            placeholder: (context, url) => Container(
              color: const Color.fromRGBO(11, 14, 23, 1),
            ),
            errorWidget: (context, url, error) => Expanded(
              child: Container(
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
