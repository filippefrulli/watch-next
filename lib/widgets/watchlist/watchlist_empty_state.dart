import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class WatchlistEmptyState extends StatelessWidget {
  final VoidCallback? onGetStarted;
  const WatchlistEmptyState({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 40, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'watchlist_empty'.tr(),
            style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'watchlist_empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (onGetStarted != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onGetStarted,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
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
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'no_filter_results'.tr(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
