import 'package:easy_localization/easy_localization.dart';
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
        Text(
          "here_recommendation".tr(),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          totalCount != 0 ? '${currentIndex + 1} / $totalCount' : '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
