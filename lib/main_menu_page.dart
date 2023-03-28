import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/recommandation_results_page.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({Key? key}) : super(key: key);

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

int currentIndex = -1;

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
  initState() {
    super.initState();
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: DelayedDisplay(
                fadingDuration: const Duration(milliseconds: 1000),
                child: Text(
                  "Hey There!",
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            moodWidget(),
            const SizedBox(height: 32),
            goButton(),
          ],
        ),
      ),
    );
  }

  Widget moodWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(15),
        ),
        color: Colors.grey[800],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'What do you feel like today?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 440,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.builder(
                itemCount: availableCategories.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        border: Border.all(
                          width: 3,
                          color: currentIndex == index ? Colors.orange : Colors.grey[300]!,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            if (currentIndex == index) {
                              currentIndex = -1;
                            } else {
                              currentIndex = index;
                            }
                          });
                        },
                        child: Text(
                          availableCategories[index]!,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
            onPressed: () => {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecommandationResultsPage(),
                ),
              ),
            },
            child: Container(
              height: 60,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(25),
                ),
                color: currentIndex != -1 ? Colors.orange : Colors.grey,
              ),
              child: Center(
                child: Text(
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
}
