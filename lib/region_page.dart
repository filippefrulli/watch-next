import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streaming_services_page.dart';

class RegionIntroPage extends StatefulWidget {
  const RegionIntroPage({Key? key}) : super(key: key);

  @override
  State<RegionIntroPage> createState() => _SecondIntroScreenState();
}

class _SecondIntroScreenState extends State<RegionIntroPage> {
  static const List<String> regions = [
    'Argentina',
    'Australia',
    'Austria',
    'Bangladesch',
    'Belgium',
    'Brazil',
    'Bulgaria',
    'Canada',
    'Chile',
    'China',
    'Columbia',
    'Croatia',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Estonia',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'Hong Kong',
    'Hungary',
    'India',
    'Indonesia',
    'Iran',
    'Irak',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Malaysia',
    'Mexico',
    'Netherlands',
    'New Zealand',
    'Norway',
    'Pakistan',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Romania',
    'Russia',
    'Saudi Arabia',
    'Serbia',
    'Slowakia',
    'Slovenia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sweden',
    'Switzerland',
    'Thailand',
    'Tunisia',
    'Turkey',
    'Ukraine',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Vietnam',
  ];

  static const List<String> regionsShort = [
    'AR',
    'AU',
    'AT',
    'BD',
    'BE',
    'BR',
    'BG',
    'CA',
    'CL',
    'CN',
    'CO',
    'HR',
    'CZ',
    'DK',
    'EG',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'HK',
    'HU',
    'IN',
    'ID',
    'IR',
    'IQ',
    'IE',
    'IL',
    'IT',
    'JP',
    'MY',
    'MX',
    'NL',
    'NZ',
    'NO',
    'PK',
    'PY',
    'PE',
    'PH',
    'PL',
    'PT',
    'RO',
    'RU',
    'SA',
    'RS',
    'SK',
    'SI',
    'ZA',
    'SK',
    'ES',
    'SE',
    'CH',
    'TH',
    'TN',
    'TR',
    'UA',
    'UK',
    'US',
    'UY',
    'VN',
  ];

  int selected = -1;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.renderView.automaticSystemUiAdjustment = false;
    return Scaffold(
      body: SafeArea(
        child: DelayedDisplay(
          delay: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 16),
              Text(
                'Select your country',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 32),
              _regions(),
              const SizedBox(height: 16),
              nextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _regions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height - 240,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: regions.length,
          itemBuilder: (context, index) {
            return _listTile(regions[index], regionsShort[index], index);
          },
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
          Container(height: 1, color: Colors.grey[200]),
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
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const StreamingServicesPage(),
                  ),
                );
              },
              child: Text(
                'Next',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        : Container();
  }
}
