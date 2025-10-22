import 'package:flutter/material.dart';

class RecommendationHeader extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final bool isLoading;

  const RecommendationHeader({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Expanded(child: Container());
    }

    return Column(
      children: [
        if (totalCount != 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentIndex + 1} / $totalCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
