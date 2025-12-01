import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool showReloadButton;
  final VoidCallback onInfoPressed;
  final VoidCallback onReloadPressed;
  final VoidCallback? onWatchlistPressed;
  final bool isInWatchlist;
  final int mediaType;

  const ActionButtons({
    super.key,
    required this.showReloadButton,
    required this.onInfoPressed,
    required this.onReloadPressed,
    this.onWatchlistPressed,
    this.isInWatchlist = false,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoButton(context),
        const SizedBox(height: 8),
        Row(
          children: [
            if (onWatchlistPressed != null) _buildWatchlistButton(context),
            if (onWatchlistPressed != null && showReloadButton) const SizedBox(width: 8),
            if (showReloadButton) _buildReloadButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
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

  Widget _buildWatchlistButton(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isInWatchlist ? Colors.orange.withValues(alpha: 0.2) : Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInWatchlist ? Colors.orange : Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onWatchlistPressed,
          child: Icon(
            isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
            color: isInWatchlist ? Colors.orange : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildReloadButton(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.orange, Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'reloaded_recommendations',
              parameters: <String, Object>{
                "type": mediaType == 0 ? "movie" : "show",
              },
            );
            onReloadPressed();
          },
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
