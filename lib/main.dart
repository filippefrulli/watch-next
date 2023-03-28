import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/main_menu_page.dart';
import 'package:watch_next/region_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive).then(
    (_) => runApp(
      const MyApp(),
    ),
  );
}

final ThemeData theme = ThemeData();

/// This Widget is the main application.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/main': (BuildContext context) => const MainMenuPage(),
      },
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: MyBehavior(),
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: theme.colorScheme.copyWith(
          primary: Colors.grey[900],
          secondary: Colors.orange,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Raleway',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 24.0,
            color: Colors.grey[200],
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 20.0,
            color: Colors.grey[200],
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
          displaySmall: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[200],
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
          labelLarge: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w400,
            color: Colors.grey[900],
            letterSpacing: 1.2,
          ),
          labelMedium: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w400,
            color: Colors.grey[900],
            letterSpacing: 1.2,
          ),
          labelSmall: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[900],
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
          bodyMedium: const TextStyle(
            fontSize: 20.0,
            color: Colors.orange,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('skip_intro') ?? false);

    if (seen && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RegionIntroPage(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 200), () {
      checkFirstSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  MainMovieListState createState() => MainMovieListState();
}

class MainMovieListState extends State<HomePage> with TickerProviderStateMixin<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Theme.of(context).primaryColor,
      statusBarColor: Colors.transparent,
    ));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: const MainMenuPage(),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
