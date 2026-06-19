import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:watch_next/utils/app_colors.dart';

class WatchlistEmptyState extends StatelessWidget {
  final VoidCallback? onGetStarted;
  const WatchlistEmptyState({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 40, color: context.appColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'watchlist_empty'.tr(),
            style: TextStyle(color: context.appColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'watchlist_empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appColors.textTertiary, fontSize: 14),
          ),
          if (onGetStarted != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onGetStarted,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: context.appColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'get_recommendations'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WatchlistNoResultsState extends StatelessWidget {
  const WatchlistNoResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: context.appColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'no_filter_results'.tr(),
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
