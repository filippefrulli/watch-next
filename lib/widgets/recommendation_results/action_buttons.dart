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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: TextButton(
        onPressed: () {
          FirebaseAnalytics.instance.logEvent(
            name: 'opened_info',
            parameters: <String, Object>{
              "type": mediaType == 0 ? "movie" : "show",
            },
          );
          onInfoPressed();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Info",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 15,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReloadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.orange, Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'reloaded_recommendations',
              parameters: <String, Object>{
                "type": mediaType == 0 ? "movie" : "show",
              },
            );
            onReloadPressed();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              AutoSizeText(
                "new".tr(),
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 15,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
