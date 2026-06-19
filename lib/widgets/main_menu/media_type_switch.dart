import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:watch_next/utils/app_colors.dart';

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
        color: context.appColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: ToggleSwitch(
        minWidth: 104.0,
        minHeight: 34.0,
        initialLabelIndex: currentIndex,
        cornerRadius: 10.0,
        animate: true,
        animationDuration: 300,
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.transparent,
        inactiveFgColor: context.appColors.textSecondary,
        totalSwitches: 2,
        labels: ['movie'.tr(), 'tv_show'.tr()],
        customTextStyles: const [
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ],
        activeBgColors: [
          [context.appColors.accent],
          [context.appColors.accent],
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
