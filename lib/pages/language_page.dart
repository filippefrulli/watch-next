import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/region_page.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  static List<String> languages = [
    'English',
    'Deutsch',
    'Italiano',
    'Français',
    'Español',
  ];

  static List<String> lang = ['en', 'de', 'it', 'fr', 'es'];

  static List<String> regions = ['US', 'DE', 'IT', 'FR', 'ES'];

  int selected = 21;

  double opacity = 1.0;

  @override
  initState() {
    super.initState();
    changeOpacity();
  }

  changeOpacity() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        opacity = opacity == 0.0 ? 1.0 : 0.0;
      });
    });
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        opacity = opacity == 0.0 ? 1.0 : 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 48),
              Stack(
                children: <Widget>[
                  Center(
                    child: Stack(
                      children: <Widget>[
                        AnimatedOpacity(
                          opacity: opacity,
                          duration: const Duration(seconds: 1),
                          child: const Text(''),
                        ),
                        AnimatedOpacity(
                          opacity: opacity == 1 ? 0 : 1,
                          duration: const Duration(seconds: 1),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 120),
                            child: Text(
                              'Welcome to Watch next',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DelayedDisplay(
                    delay: const Duration(seconds: 5),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Select your language',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 64),
                        _languages(),
                        const SizedBox(height: 64),
                        _next(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _next() {
    if (selected < 10) {
      return DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: TextButton(
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            bool seen = prefs.getBool('skip_intro') ?? false;
            if (context.mounted && seen) {
              Navigator.of(context).pop();
            } else if (mounted && !seen) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const RegionIntroPage(),
                ),
              );
            }
          },
          child: Text(
            "done".tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _languages() {
    return SizedBox(
      height: 370,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.builder(
          itemCount: languages.length,
          itemBuilder: (context, index) {
            return _listTile(languages[index], lang[index], regions[index], index);
          },
        ),
      ),
    );
  }

  Widget _listTile(String language, String lang, String region, int index) {
    return TextButton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _text(language, index),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.grey[600]),
        ],
      ),
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (mounted) {
          context.setLocale(Locale(lang, region));
        }
        prefs.setInt('language_number', index);

        setState(() {
          selected = index;
        });
      },
    );
  }

  Widget _text(String language, int index) {
    if (selected == index) {
      return Text(
        language,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      return Text(
        language,
        style: Theme.of(context).textTheme.displayMedium,
      );
    }
  }
}
