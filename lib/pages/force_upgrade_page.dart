import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_next/utils/app_colors.dart';
import 'package:watch_next/utils/secrets.dart';

/// Full-screen, non-dismissible gate shown when the running build is older than
/// the minimum supported build (see [VersionGateService]). The only action is
/// to open the store and update.
class ForceUpgradePage extends StatelessWidget {
  const ForceUpgradePage({super.key});

  Future<void> _openStore() async {
    final Uri url = Uri.parse(Platform.isIOS ? appStoreUrl : playStoreUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Block the system back button / swipe — there is no way past this screen
    // except updating.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.system_update_rounded, size: 72, color: colors.accent),
                  const SizedBox(height: 28),
                  Text(
                    "force_upgrade_title".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "force_upgrade_message".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "force_upgrade_button".tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
