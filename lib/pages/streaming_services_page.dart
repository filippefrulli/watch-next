import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/main_menu_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/utils/constants.dart';

///This is the page where you enter the movie you saw
class StreamingServicesPage extends StatefulWidget {
  const StreamingServicesPage({
    Key? key,
  }) : super(key: key);
  @override
  State<StreamingServicesPage> createState() => _StreamingServicesPage();
}

class _StreamingServicesPage extends State<StreamingServicesPage> with TickerProviderStateMixin {
  List<int> streamingServicesIds = List<int>.empty(growable: true);

  List<bool> selectedStreamingServices = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  List<int> selectedServicesIndex = [];

  @override
  void initState() {
    if (Platform.isAndroid) {
      streamingServicesIds = [8, 9, 350, 337, 384, 15, 531, 386];
    } else {
      streamingServicesIds = [8, 9, 350, 384, 15, 531, 386];
    }
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
          'Select your streaming services',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 16),
        streamingOptions(),
        Expanded(
          child: Container(),
        ),
        closeButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget streamingOptions() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 230,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
        ),
        itemCount: streamingServicesIds.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(0),
              ),
              onPressed: () {
                setState(() {
                  selectedStreamingServices[index] = !selectedStreamingServices[index];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(25),
                  ),
                  border: Border.all(
                    width: 3,
                    color: selectedStreamingServices[index] ? Colors.orange : Colors.white,
                  ),
                  color: Colors.grey[300],
                ),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Image.asset(
                    Platform.isIOS ? streamingServicesLogosIos[index] : streamingServicesLogos[index],
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget closeButton() {
    return selectedStreamingServices.contains(true)
        ? SizedBox(
            height: 50,
            child: Center(
              child: TextButton(
                  onPressed: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setBool('skip_intro', true);
                    selectedStreamingServices.asMap().forEach(
                          (index, value) => {
                            if (value)
                              {
                                selectedServicesIndex.add(index),
                              }
                          },
                        );
                    await DatabaseService.saveStreamingServices(
                        selectedServicesIndex, streamingServicesIds, streamingServicesLogos);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainMenuPage(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Close',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )),
            ),
          )
        : Container();
  }
}
