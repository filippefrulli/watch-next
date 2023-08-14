import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/region.dart';
import 'streaming_services_page.dart';

class RegionIntroPage extends StatefulWidget {
  const RegionIntroPage({Key? key}) : super(key: key);

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
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
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
            const SizedBox(height: 16),
            _regions(),
            Expanded(
              child: Container(),
            ),
            nextButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _regions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(
            color: Colors.grey[700]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
        height: MediaQuery.of(context).size.height * 0.7,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: availableRegions.length,
            itemBuilder: (context, index) {
              return _listTile(availableRegions[index].englishName!, availableRegions[index].iso!, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _listTile(String country, String region, int index) {
    return TextButton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _text(country, index),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[600]),
        ],
      ),
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('region', region);
        prefs.setInt('region_number', index);

        prefs.setBool('seen', true);

        setState(() {
          selected = index;
        });
      },
    );
  }

  Widget _text(String country, int index) {
    if (selected == index) {
      return Text(
        country,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      return Text(
        country,
        style: Theme.of(context).textTheme.displayMedium,
      );
    }
  }

  Widget nextButton() {
    return selected > -1
        ? DelayedDisplay(
            delay: const Duration(milliseconds: 100),
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const StreamingServicesPage(),
                  ),
                );
              },
              child: Text(
                "done".tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        : Container();
  }
}
