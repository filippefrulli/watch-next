import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/utils/app_colors.dart';

/// A custom sliding segmented control for choosing Movie vs TV show.
///
/// An animated thumb slides between the two segments, the selected label
/// brightens and gains weight, and each segment carries an icon — the elegant,
/// tactile pattern common in modern apps (iOS segmented control, Linear, etc.).
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
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Sliding thumb.
              AnimatedAlign(
                alignment: currentIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.appColors.accent, context.appColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.accent.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Labels.
              Row(
                children: [
                  _segment(context, 0, Icons.movie_outlined, 'movie'.tr()),
                  _segment(context, 1, Icons.live_tv_outlined, 'tv_show'.tr()),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(BuildContext context, int index, IconData icon, String label) {
    final selected = currentIndex == index;
    final color = selected ? Colors.white : context.appColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggle(index),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
