import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_next/main_menu_page.dart';
import 'constants.dart';

///This is the page where you enter the movie you saw
class StreamingServicesPage extends StatefulWidget {
  const StreamingServicesPage({
    Key? key,
  }) : super(key: key);
  @override
  State<StreamingServicesPage> createState() => _StreamingServicesPage();
}

class _StreamingServicesPage extends State<StreamingServicesPage> with TickerProviderStateMixin {
  List<int> streamingServicesIds = [8, 9, 350, 337, 384, 15, 531, 386];

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).primaryColor,
        statusBarColor: Colors.transparent,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: _streamingList(),
      ),
    );
  }

  Widget _streamingList() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'Select your streaming services',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 32),
        Expanded(
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
                        streamingServicesLogos[index],
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        selectedStreamingServices.contains(true)
            ? SizedBox(
                height: 50,
                child: Center(
                  child: TextButton(
                      onPressed: () => {
                            selectedStreamingServices.asMap().forEach(
                                  (index, value) => {
                                    if (value)
                                      {
                                        selectedServicesIndex.add(index),
                                      }
                                  },
                                ),
                            // DatabaseService.saveStreamingServices(
                            //     selectedServicesIndex, streamingServicesIds, streamingServicesLogos),
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MainMenuPage(),
                              ),
                            ),
                          },
                      child: Text(
                        'Close',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )),
                ),
              )
            : Container(),
        const SizedBox(height: 16),
      ],
    );
  }
}
