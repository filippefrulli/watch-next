import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/pages/language_page.dart';
import 'package:watch_next/pages/region_page.dart';
import 'package:watch_next/pages/streaming_services_page.dart';
import 'package:watch_next/widgets/shared/divider.dart';
import 'package:watch_next/widgets/shared/privacy_policy_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      body: pageBody(),
    );
  }

  Widget pageBody() {
    return SafeArea(
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'settings'.tr(),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 8),
                    _sectionTitle('preferences'.tr()),
                    const SizedBox(height: 12),
                    _settingsCard(
                      children: [
                        _settingsTile(
                          title: "change_region".tr(),
                          icon: Icons.public_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegionIntroPage(),
                              ),
                            );
                          },
                        ),
                        _divider(),
                        _settingsTile(
                          title: "edit_streaming".tr(),
                          icon: Icons.tv_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StreamingServicesPage(),
                              ),
                            );
                          },
                        ),
                        _divider(),
                        _settingsTile(
                          title: "edit_language".tr(),
                          icon: Icons.language_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LanguagePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('support'.tr()),
                    const SizedBox(height: 12),
                    _settingsCard(
                      children: [
                        _settingsTile(
                          title: "rate_app".tr(),
                          icon: Icons.star_rounded,
                          onTap: () async {
                            if (Platform.isAndroid) {
                              final Uri url = Uri.parse(
                                  'https://play.google.com/store/apps/details?id=com.filippefrulli.watch_next');
                              if (!await launchUrl(url)) {
                                throw Exception('Could not launch url');
                              }
                            } else if (Platform.isIOS) {
                              final Uri url = Uri.parse(
                                  'https://apps.apple.com/de/app/watch-next-ai-movie-assistant/id6450368827?l=en');
                              if (!await launchUrl(url)) {
                                throw Exception('Could not launch url');
                              }
                            }
                          },
                        ),
                        _divider(),
                        _settingsTile(
                          title: "share".tr(),
                          icon: Icons.share_rounded,
                          onTap: () {
                            if (Platform.isAndroid) {
                              Share.share(
                                  'Check out my app: https://play.google.com/store/apps/details?id=com.filippefrulli.watch_next');
                            } else if (Platform.isIOS) {
                              Share.share(
                                  'Check out my app: https://apps.apple.com/de/app/watch-next-ai-movie-assistant/id6450368827?l=en');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('information'.tr()),
                    const SizedBox(height: 12),
                    _settingsCard(
                      children: [
                        _settingsTile(
                          title: "about".tr(),
                          icon: Icons.info_rounded,
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Watch next',
                              children: [
                                Image.asset(
                                  'assets/TMDb.png',
                                  width: 40.0,
                                  height: 40.0,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Watch next uses TMDb but is not endorsed or certified by TMDb.',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Watch provider information is provided by JustWatch.',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We do not claim ownership of any of the images or data provided.',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const DividerWidget(padding: 0, height: 16),
                              ],
                            );
                          },
                        ),
                        _divider(),
                        _settingsTile(
                          title: "privacy_policy".tr(),
                          icon: Icons.receipt_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicy(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[600],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[800],
      indent: 72,
    );
  }
}
