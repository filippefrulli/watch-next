import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class MediaTypeSwitch extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onToggle;

  const MediaTypeSwitch({
    super.key,
    required this.currentIndex,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: ToggleSwitch(
        minWidth: 140.0,
        minHeight: 48.0,
        initialLabelIndex: currentIndex,
        cornerRadius: 12.0,
        animate: true,
        animationDuration: 300,
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.transparent,
        inactiveFgColor: Colors.grey[400],
        totalSwitches: 2,
        labels: ['movie'.tr(), 'tv_show'.tr()],
        customTextStyles: const [
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ],
        activeBgColors: const [
          [Colors.orange],
          [Colors.orange],
        ],
        onToggle: (index) {
          if (index != null) {
            onToggle(index);
          }
        },
      ),
    );
  }
}
