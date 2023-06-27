import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/region_page.dart';

import 'pages/main_menu_page.dart';

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
      debugShowCheckedModeBanner: false,
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
          primary: const Color.fromRGBO(13, 6, 59, 1),
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
          bodySmall: TextStyle(
            fontSize: 15.0,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
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
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark));

//Setting SystmeUIMode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

    return WillPopScope(
      onWillPop: () async => false,
      child: const Scaffold(
        backgroundColor: Color.fromRGBO(11, 14, 23, 1),
        body: MainMenuPage(),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
