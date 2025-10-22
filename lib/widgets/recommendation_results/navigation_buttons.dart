import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
        IconButton(
          onPressed: () {
            if (currentIndex > 0) {
              onPrevious();
              FirebaseAnalytics.instance.logEvent(name: 'moved_back');
            }
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 32,
            color: currentIndex == 0 ? Colors.grey[600] : Colors.white,
          ),
        ),
        Expanded(child: Container()),
        _buildAcceptButton(context),
        Expanded(child: Container()),
        IconButton(
          onPressed: () {
            if (currentIndex < totalCount - 1) {
              onNext();
              FirebaseAnalytics.instance.logEvent(name: 'moved_forward');
            }
          },
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 32,
            color: currentIndex == totalCount - 1 ? Colors.grey[600] : Colors.white,
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
          height: 50,
          width: 150,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            color: Colors.orange,
          ),
          child: TextButton(
            onPressed: onAccept,
            child: Text(
              "accept".tr(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}
