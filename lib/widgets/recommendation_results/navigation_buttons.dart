import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAccept;

  const NavigationButtons({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
    required this.onAccept,
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
            border: Border.all(
              color: currentIndex == 0 ? Theme.of(context).colorScheme.outline : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
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
        _buildAcceptButton(context),
        Expanded(child: Container()),
        // Next button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: currentIndex == totalCount - 1
                  ? Theme.of(context).colorScheme.outline
                  : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
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

  Widget _buildAcceptButton(BuildContext context) {
    return Center(
      child: DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Colors.orange, Color(0xFFFF8C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton(
            onPressed: onAccept,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              "accept".tr(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
