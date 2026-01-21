import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool showReloadButton;
  final VoidCallback onReloadPressed;
  final VoidCallback? onWatchlistPressed;
  final bool isInWatchlist;
  final int mediaType;

  const ActionButtons({
    super.key,
    required this.showReloadButton,
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
        if (onWatchlistPressed != null) _buildWatchlistButton(context),
        if (onWatchlistPressed != null && showReloadButton) const SizedBox(height: 8),
        if (showReloadButton) _buildReloadButton(context),
      ],
    );
  }

  Widget _buildWatchlistButton(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onWatchlistPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isInWatchlist ? Icons.bookmark : Icons.add,
                    key: ValueKey<bool>(isInWatchlist),
                    color: isInWatchlist ? Theme.of(context).colorScheme.secondary : Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'watchlist'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReloadButton(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.secondary, const Color(0xFFFF8C00)],
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'load_more'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
