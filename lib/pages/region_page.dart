import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/region.dart';
import 'package:watch_next/services/user_action_service.dart';
import 'package:watch_next/pages/home_page.dart';

class RegionIntroPage extends StatefulWidget {
  const RegionIntroPage({super.key});

  @override
  State<RegionIntroPage> createState() => _SecondIntroScreenState();
}

class _SecondIntroScreenState extends State<RegionIntroPage> {
  String? _selectedIso;
  String? _initialRegion;
  List<Region> _filteredRegions = availableRegions;

  @override
  initState() {
    availableRegions.sort((a, b) => a.englishName!.compareTo(b.englishName!));
    super.initState();
    _loadInitialRegion();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredRegions =
          availableRegions.where((region) => region.englishName!.toLowerCase().contains(value.toLowerCase())).toList();
      _selectedIso = null;
    });
  }

  Future<void> _loadInitialRegion() async {
    final prefs = await SharedPreferences.getInstance();
    _initialRegion = prefs.getString('region');

    final String? savedRegion = prefs.getString('region');
    if (savedRegion != null) {
      if (mounted) setState(() => _selectedIso = savedRegion);
    } else {
      final countryCode = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      if (countryCode != null) {
        final match = _filteredRegions.firstWhere(
          (r) => r.iso == countryCode,
          orElse: () => Region(iso: null, englishName: null),
        );
        if (match.iso != null) {
          await prefs.setString('region', match.iso!);
          await prefs.setBool('seen', true);
          if (mounted) setState(() => _selectedIso = match.iso);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
              const SizedBox(height: 32),
              Text(
                "select_country".tr(),
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "region_subtitle".tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 14,
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              _stepDots(2),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "search_country".tr(),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.tertiary,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _regions()),
              const SizedBox(height: 12),
              nextButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
    );
  }

  String _isoToFlag(String iso) {
    const base = 0x1F1E6 - 0x41;
    return iso.toUpperCase().split('').map((c) => String.fromCharCode(c.codeUnitAt(0) + base)).join();
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

  Widget _regions() {
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filteredRegions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              return _listTile(_filteredRegions[index].englishName!, _filteredRegions[index].iso!, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _listTile(String country, String region, int index) {
    bool isSelected = _selectedIso == region;

    return Material(
      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('region', region);
          prefs.setBool('seen', true);

          setState(() {
            _selectedIso = region;
          });
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
                    _isoToFlag(region),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  country,
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

  Widget nextButton() {
    return _selectedIso != null
        ? AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
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
                    // Log region change only when submitting
                    final prefs = await SharedPreferences.getInstance();
                    final currentRegion = prefs.getString('region');
                    if (_initialRegion != currentRegion && currentRegion != null) {
                      UserActionService.logRegionChanged(
                        fromRegion: _initialRegion ?? 'none',
                        toRegion: currentRegion,
                      );
                    }

                    prefs.setBool('skip_intro', true);

                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, _) => const TabNavigationPage(),
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
          )
        : Container();
  }
}
