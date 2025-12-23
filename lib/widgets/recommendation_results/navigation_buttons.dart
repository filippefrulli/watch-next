import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onInfoPressed;

  const NavigationButtons({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Container()),
        // Previous button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () {
              if (currentIndex > 0) {
                onPrevious();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 24,
              color: currentIndex == 0 ? Colors.grey[600] : Colors.white,
            ),
          ),
        ),
        Expanded(child: Container()),
        _buildInfoButton(context),
        Expanded(child: Container()),
        // Next button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () {
              if (currentIndex < totalCount - 1) {
                onNext();
              }
            },
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 24,
              color: currentIndex == totalCount - 1 ? Colors.grey[600] : Colors.white,
            ),
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return Center(
      child: DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextButton(
            onPressed: onInfoPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  "open_info".tr(),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
