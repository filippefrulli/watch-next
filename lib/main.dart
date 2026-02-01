import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/firebase_options.dart';
import 'package:watch_next/pages/language_page.dart';
import 'package:watch_next/services/notification_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'pages/home_page.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Disable analytics in debug mode
  if (kDebugMode) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  }

  // Initialize notification service
  await NotificationService.initialize();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemStatusBarContrastEnforced: true,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive).then(
    (_) => runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('it', 'IT'),
          Locale('de', 'DE'),
          Locale('fr', 'FR'),
          Locale('es', 'ES'),
          Locale('pt', 'BR'),
          Locale('ja', 'JP'),
          Locale('hi', 'IN'),
        ],
        path: 'assets/translations',
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: const MyApp(),
      ),
    ),
  );
}

final ThemeData theme = ThemeData();

// Global navigator key for handling notifications when app is in background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// This Widget is the main application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: MyBehavior(),
            child: child!,
          );
        },
        theme: ThemeData(
          colorScheme: theme.colorScheme.copyWith(
            primary: const Color.fromARGB(255, 14, 14, 14),
            secondary: Colors.orange,
            tertiary: const Color.fromARGB(255, 30, 31, 31),
            outline: Colors.grey[800],
            brightness: Brightness.dark,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
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
            bodyLarge: TextStyle(
              fontSize: 16.0,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
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
            headlineSmall: TextStyle(
              fontSize: 16.0,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const Splash(),
      ),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('skip_intro') ?? false);

    if (seen && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LanguagePage(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize user tracking on app open
    UserActionService.initializeUser();
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
  const HomePage({super.key});

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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: [SystemUiOverlay.top]);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {},
      child: const Scaffold(
        backgroundColor: Color.fromRGBO(11, 14, 23, 1),
        resizeToAvoidBottomInset: false,
        body: TabNavigationPage(),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
