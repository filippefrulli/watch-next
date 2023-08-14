import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/pages/region_page.dart';
import 'package:watch_next/pages/streaming_services_page.dart';
import 'package:watch_next/widgets/divider.dart';
import 'package:watch_next/widgets/privacy_policy_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(
          Icons.chevron_left,
          color: Colors.grey[900],
          size: 32,
        ),
      ),
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: pageBody(),
    );
  }

  Widget pageBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 64),
            TextButton(
              child: _row(("change_region".tr()), Icons.public),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegionIntroPage(),
                  ),
                );
              },
            ),
            TextButton(
              child: _row(("edit_streaming".tr()), Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StreamingServicesPage(),
                  ),
                );
              },
            ),
            const DividerWidget(padding: 0, height: 32),
            TextButton(
              child: _row(("rate_app".tr()), Icons.star),
              onPressed: () async {
                if (Platform.isAndroid) {
                  final Uri url =
                      Uri.parse('https://play.google.com/store/apps/details?id=com.filippefrulli.watch_next');
                  if (!await launchUrl(url)) {
                    throw Exception('Could not launch url');
                  }
                } else if (Platform.isIOS) {
                  final Uri url =
                      Uri.parse('https://apps.apple.com/de/app/watch-next-ai-movie-assistant/id6450368827?l=en');
                  if (!await launchUrl(url)) {
                    throw Exception('Could not launch url');
                  }
                }
              },
            ),
            TextButton(
              child: _row(("share".tr()), Icons.share),
              onPressed: () {
                if (Platform.isAndroid) {
                  Share.share(
                      'Check out my app: https://play.google.com/store/apps/details?id=com.filippefrulli.watch_next');
                } else if (Platform.isIOS) {
                  Share.share(
                      'Check out my app: https://apps.apple.com/de/app/watch-next-ai-movie-assistant/id6450368827?l=en');
                }
              },
            ),
            const DividerWidget(padding: 0, height: 32),
            TextButton(
              child: _row(("about".tr()), Icons.info),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Watch next',
                  applicationIcon: const FlutterLogo(),
                  applicationVersion: "1.0.0",
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/TMDb.png',
                        width: 50.0,
                        height: 50.0,
                      ),
                    ),
                    const Text(
                      'Watch next uses TMDb but is not endorsed or certified by TMDb',
                    ),
                    const SizedBox(height: 20),
                    const DividerWidget(padding: 0, height: 16),
                    const SizedBox(height: 20),
                    const Text(
                      'We do not claim ownership of any of the images or data provided',
                    ),
                  ],
                );
              },
            ),
            const DividerWidget(padding: 0, height: 16),
            TextButton(
              child: _row(("privacy_policy".tr()), Icons.receipt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicy(),
                  ),
                );
              },
            ),
            const DividerWidget(padding: 0, height: 16),
          ],
        ),
      ),
    );
  }

  Widget _row(String text, IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 16),
          Text(text, style: Theme.of(context).textTheme.displayMedium),
        ],
      ),
    );
  }
}
