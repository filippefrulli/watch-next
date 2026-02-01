import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/widgets/main_menu/examples_dialog.dart';
import 'package:watch_next/widgets/main_menu/query_settings_panel.dart';

class SecondaryActionsRow extends StatelessWidget {
  final QuerySettings querySettings;
  final ValueChanged<QuerySettings> onSettingsChanged;
  final bool isMovie;

  const SecondaryActionsRow({
    super.key,
    required this.querySettings,
    required this.onSettingsChanged,
    required this.isMovie,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Filters button
        _ActionButton(
          icon: Icons.tune_rounded,
          label: "filters".tr(),
          hasIndicator: querySettings.hasActiveFilters,
          onTap: () => QuerySettingsPanel.show(
            context,
            initialSettings: querySettings,
            onSettingsChanged: onSettingsChanged,
            isMovie: isMovie,
          ),
        ),
        const SizedBox(width: 24),
        // Examples button
        _ActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: "examples".tr(),
          onTap: () => ExamplesDialog.show(context, isMovie: isMovie),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasIndicator;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    if (hasIndicator)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
