import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/pages/language_page.dart';
import 'package:watch_next/pages/region_page.dart';
import 'package:watch_next/pages/streaming_services_page.dart';
import 'package:watch_next/services/feedback_service.dart';
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
      backgroundColor: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.tertiary,
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
                              SharePlus.instance.share(ShareParams(
                                  text:
                                      'Check out my app: https://play.google.com/store/apps/details?id=com.filippefrulli.watch_next'));
                            } else if (Platform.isIOS) {
                              SharePlus.instance.share(ShareParams(
                                  text:
                                      'Check out my app: https://apps.apple.com/de/app/watch-next-ai-movie-assistant/id6450368827?l=en'));
                            }
                          },
                        ),
                        _divider(),
                        _settingsTile(
                          title: "send_feedback".tr(),
                          icon: Icons.feedback_rounded,
                          onTap: () {
                            _showFeedbackDialog();
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
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
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
                  color: Colors.orange.withValues(alpha: 0.15),
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
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
      color: Theme.of(context).colorScheme.outline,
      indent: 72,
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'feedback_settings_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'feedback_settings_message'.tr(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: TextField(
                    controller: feedbackController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'feedback_hint'.tr(),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(dialogContext),
                            child: Center(
                              child: Text(
                                'cancel'.tr(),
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSubmitting ? Colors.orange.withValues(alpha: 0.7) : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isSubmitting
                                ? null
                                : () async {
                                    if (feedbackController.text.trim().isEmpty) return;

                                    setDialogState(() => isSubmitting = true);

                                    final success = await FeedbackService.submitFeedback(
                                      feedbackController.text,
                                    );

                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);

                                    Fluttertoast.showToast(
                                      msg: success ? 'feedback_sent'.tr() : 'feedback_error'.tr(),
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: success ? Colors.green : Colors.red,
                                      textColor: Colors.white,
                                    );
                                  },
                            child: Center(
                              child: Text(
                                isSubmitting ? 'sending'.tr() : 'send'.tr(),
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
