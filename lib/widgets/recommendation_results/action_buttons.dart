import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/utils/app_colors.dart';

class ActionButtons extends StatelessWidget {
  final bool showReloadButton;
  final VoidCallback onReloadPressed;
  final VoidCallback? onWatchlistPressed;
  final bool isInWatchlist;
  final VoidCallback? onWatchedPressed;
  final bool isWatched;
  final int? watchedRating;
  final int mediaType;
  final VoidCallback? onNotInterestedPressed;
  final bool isNotInterested;

  const ActionButtons({
    super.key,
    required this.showReloadButton,
    required this.onReloadPressed,
    this.onWatchlistPressed,
    this.isInWatchlist = false,
    this.onWatchedPressed,
    this.isWatched = false,
    this.watchedRating,
    required this.mediaType,
    this.onNotInterestedPressed,
    this.isNotInterested = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onWatchlistPressed != null) _buildWatchlistButton(context),
            if (onWatchlistPressed != null && onWatchedPressed != null) const SizedBox(width: 8),
            if (onWatchedPressed != null) _buildWatchedButton(context),
            if (onWatchedPressed != null && onNotInterestedPressed != null) const SizedBox(width: 8),
            if (onNotInterestedPressed != null) _buildNotInterestedButton(context),
          ],
        ),
        if ((onWatchlistPressed != null || onWatchedPressed != null) && showReloadButton) const SizedBox(height: 8),
        if (showReloadButton) _buildReloadButton(context),
      ],
    );
  }

  Widget _buildWatchlistButton(BuildContext context) {
    return Container(
      width: 48,
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
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                key: ValueKey<bool>(isInWatchlist),
                color: isInWatchlist ? Theme.of(context).colorScheme.secondary : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchedButton(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onWatchedPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                Icons.check,
                key: ValueKey<bool>(isWatched),
                color: isWatched ? Colors.green[400] : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotInterestedButton(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onNotInterestedPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                Icons.close,
                key: ValueKey<bool>(isNotInterested),
                color: isNotInterested ? Theme.of(context).colorScheme.secondary : Colors.white,
                size: 22,
              ),
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
          colors: [Theme.of(context).colorScheme.secondary, context.appColors.accentDark],
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
