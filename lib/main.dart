import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/firebase_options.dart';
import 'package:watch_next/pages/force_upgrade_page.dart';
import 'package:watch_next/pages/intro_page.dart';
import 'package:watch_next/services/notification_service.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/services/version_gate_service.dart';
import 'pages/home_page.dart';
import 'package:watch_next/utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check attests that requests to our Cloud Functions come from a genuine,
  // unmodified build of this app, so the API-key proxy can't be abused by
  // scripts that scraped a function URL. Debug builds use the debug provider
  // (register the printed debug token in the Firebase console); release builds
  // use Play Integrity (Android) and App Attest (iOS).
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? AppleDebugProvider()
        : AppleAppAttestProvider(),
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

  // The app is dark-only, so the system bars need light (white) icons to stay
  // legible now that they're drawn on top of our background.
  //
  // Deliberately no statusBarColor / systemNavigationBarColor / divider color:
  // those go through Window.setStatusBarColor & friends, which Android 15
  // deprecated and Play Console flags. Under edge-to-edge the bars are
  // transparent anyway and the app paints behind them.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark, // iOS: dark background -> light icons
  ));

  // Edge-to-edge on every Android version, not just 15+. Targeting SDK 35
  // makes Android force it regardless; requesting it explicitly is the
  // backward-compatible equivalent of enableEdgeToEdge().
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge).then(
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
    return MaterialApp(
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
            primary: AppColors.defaults.background,
            secondary: AppColors.defaults.accent,
            tertiary: AppColors.defaults.surface,
            outline: AppColors.defaults.border,
            brightness: Brightness.dark,
          ),
          extensions: const [AppColors.defaults],
          // Keep all SnackBars at a compact, consistent size — otherwise they
          // inherit the large bodyMedium (20px) default.
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.defaults.surface2,
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              color: AppColors.defaults.textPrimary,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
            displayMedium: TextStyle(
              fontSize: 20.0,
              color: AppColors.defaults.textPrimary,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
            displaySmall: TextStyle(
              fontSize: 16.0,
              color: AppColors.defaults.textPrimary,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
            labelLarge: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w400,
              color: AppColors.defaults.background,
              letterSpacing: 1.2,
            ),
            labelMedium: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w400,
              color: AppColors.defaults.background,
              letterSpacing: 1.2,
            ),
            labelSmall: TextStyle(
              fontSize: 16.0,
              color: AppColors.defaults.background,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
            bodyLarge: TextStyle(
              fontSize: 16.0,
              color: AppColors.defaults.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: TextStyle(
              fontSize: 20.0,
              color: AppColors.defaults.accent,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
            bodySmall: TextStyle(
              fontSize: 15.0,
              color: AppColors.defaults.textTertiary,
              fontWeight: FontWeight.w400,
            ),
            headlineSmall: TextStyle(
              fontSize: 16.0,
              color: AppColors.defaults.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const Splash(),
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
    // Force-upgrade gate: builds older than the Remote Config minimum (e.g.
    // ones that still call the third-party APIs directly with rotated keys) are
    // sent to a blocking update screen. Fails open, so a config/network error
    // never locks anyone out.
    if (await VersionGateService.isUpdateRequired()) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ForceUpgradePage()),
        );
      }
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('skip_intro') ?? false);

    if (seen && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const IntroPage(),
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
    // Applied once here rather than on every build. The overlay style matches
    // the one set in main() — see the note there on why no bar colours are set.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.defaults.background,
        resizeToAvoidBottomInset: false,
        body: const TabNavigationPage(),
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
