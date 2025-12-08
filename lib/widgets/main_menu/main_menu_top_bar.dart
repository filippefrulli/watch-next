import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/pages/settings_page.dart';

class MainMenuTopBar extends StatelessWidget {
  const MainMenuTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 48, height: 48),
        _buildTitle(context),
        _buildSettingsButton(context),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return DelayedDisplay(
      fadingDuration: const Duration(milliseconds: 1000),
      child: Text(
        "hey_there".tr(),
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
