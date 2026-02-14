import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/home_page.dart';
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
                  const SizedBox(height: 40),
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
                  // Auto-detect region from the selected language
                  final selectedRegion = regions[selected];
                  prefs.setString('region', selectedRegion);
                  prefs.setInt('region_number', selected);
                  prefs.setBool('seen', true);
                  prefs.setBool('skip_intro', true);

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const TabNavigationPage(),
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
