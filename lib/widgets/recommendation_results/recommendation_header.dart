import 'package:flutter/material.dart';
import 'package:watch_next/utils/app_colors.dart';

class RecommendationHeader extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final bool isLoading;
  final VoidCallback? onClose;
  final VoidCallback? onShare;

  const RecommendationHeader({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.isLoading,
    this.onClose,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Expanded(child: Container());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (onShare != null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share, color: Colors.white, size: 22),
              ),
            )
          else
            const SizedBox(width: 48), // Balance the close button on the right
          Expanded(
            child: Center(
              child: totalCount != 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.appColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentIndex + 1} / $totalCount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (onClose != null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
