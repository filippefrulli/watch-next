import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/streaming_services_page.dart';
import 'package:watch_next/services/user_action_service.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

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
    'Português',
    '日本語',
    'हिन्दी',
  ];

  static List<String> lang = ['en', 'de', 'it', 'fr', 'es', 'pt', 'ja', 'hi'];

  static List<String> regions = ['US', 'DE', 'IT', 'FR', 'ES', 'BR', 'JP', 'IN'];

  static List<String> languageFlags = ['🇺🇸', '🇩🇪', '🇮🇹', '🇫🇷', '🇪🇸', '🇧🇷', '🇯🇵', '🇮🇳'];

  int selected = 21;
  String? _initialLanguage;

  @override
  initState() {
    super.initState();
    _loadInitialLanguage();
  }

  Future<void> _loadInitialLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _initialLanguage = prefs.getString('lang');

    final int? savedIndex = prefs.getInt('language_number');
    if (savedIndex != null && savedIndex < lang.length) {
      if (mounted) setState(() => selected = savedIndex);
    } else {
      final deviceLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final index = lang.indexOf(deviceLang);
      if (index != -1) {
        await prefs.setInt('language_number', index);
        await prefs.setString('lang', '${lang[index]}-${regions[index]}');
        if (mounted) {
          context.setLocale(Locale(lang[index], regions[index]));
          setState(() => selected = index);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: body(),
    );
  }

  Widget body() {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Select your language',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _stepDots(0),
                  const SizedBox(height: 24),
                  _languages(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _next(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _next() {
    if (selected < 10) {
      return DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.orange[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                bool seen = prefs.getBool('skip_intro') ?? false;

                // Log language change only when submitting
                final currentLang = prefs.getString('lang');
                if (_initialLanguage != currentLang && currentLang != null) {
                  UserActionService.logLanguageChanged(
                    fromLanguage: _initialLanguage ?? 'none',
                    toLanguage: currentLang,
                  );
                }

                if (mounted && seen) {
                  Navigator.of(context).pop();
                } else if (mounted && !seen) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, _) => const StreamingServicesPage(),
                      transitionsBuilder: (context, animation, _, child) => SlideTransition(
                        position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeInOut))
                            .animate(animation),
                        child: child,
                      ),
                      transitionDuration: const Duration(milliseconds: 550),
                    ),
                  );
                }
              },
              child: Center(
                child: Text(
                  "done".tr().toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _stepDots(int step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == step ? 20 : 10,
          height: 8,
          decoration: BoxDecoration(
            color: i == step ? Colors.orange : Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _languages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: languages.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              return _listTile(languages[index], lang[index], regions[index], index);
            },
          ),
        ),
      ),
    );
  }

  Widget _listTile(String language, String lang, String region, int index) {
    bool isSelected = selected == index;

    return Material(
      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (mounted) {
            context.setLocale(Locale(lang, region));

            prefs.setInt('language_number', index);
            prefs.setString('lang', '$lang-$region');

            setState(() {
              selected = index;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    languageFlags[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  language,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.orange : Colors.white,
                      ),
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
