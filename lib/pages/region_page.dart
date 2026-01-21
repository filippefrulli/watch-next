import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/region.dart';
import 'streaming_services_page.dart';

class RegionIntroPage extends StatefulWidget {
  const RegionIntroPage({super.key});

  @override
  State<RegionIntroPage> createState() => _SecondIntroScreenState();
}

class _SecondIntroScreenState extends State<RegionIntroPage> {
  int selected = -1;

  @override
  initState() {
    availableRegions.sort((a, b) => a.englishName!.compareTo(b.englishName!));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: DelayedDisplay(
        delay: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 48),
            Text(
              "select_country".tr(),
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _regions(),
            ),
            const SizedBox(height: 16),
            nextButton(),
            const SizedBox(height: 32),
          ],
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
            itemCount: availableRegions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              return _listTile(availableRegions[index].englishName!, availableRegions[index].iso!, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _listTile(String country, String region, int index) {
    bool isSelected = selected == index;

    return Material(
      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('region', region);
          prefs.setInt('region_number', index);

          prefs.setBool('seen', true);

          setState(() {
            selected = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 24,
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
    return selected > -1
        ? DelayedDisplay(
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const StreamingServicesPage(),
                      ),
                    );
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
