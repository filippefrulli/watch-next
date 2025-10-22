import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool showReloadButton;
  final VoidCallback onInfoPressed;
  final VoidCallback onReloadPressed;
  final int mediaType;

  const ActionButtons({
    super.key,
    required this.showReloadButton,
    required this.onInfoPressed,
    required this.onReloadPressed,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInfoButton(context),
        showReloadButton ? _buildReloadButton(context) : Container(),
      ],
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        FirebaseAnalytics.instance.logEvent(
          name: 'opened_info',
          parameters: <String, Object>{
            "type": mediaType == 0 ? "movie" : "show",
          },
        );
        onInfoPressed();
      },
      child: Container(
        height: 42,
        width: 120,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: Colors.grey[800],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Info",
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_less, size: 32, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildReloadButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        FirebaseAnalytics.instance.logEvent(
          name: 'reloaded_recommendations',
          parameters: <String, Object>{
            "type": mediaType == 0 ? "movie" : "show",
          },
        );
        onReloadPressed();
      },
      child: Container(
        height: 42,
        width: 120,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.orange,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: AutoSizeText(
                "new".tr(),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.refresh, size: 32, color: Colors.grey[900]),
          ],
        ),
      ),
    );
  }
}
