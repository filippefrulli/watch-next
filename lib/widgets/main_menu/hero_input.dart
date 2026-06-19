import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/utils/app_colors.dart';

class HeroInput extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey textFieldKey;
  final bool isLongEnough;
  final bool hasText;
  final bool enableLoading;
  final VoidCallback? onGoPressed;
  final bool isMovie;
  final bool hasActiveFilters;
  final VoidCallback? onFiltersPressed;

  const HeroInput({
    super.key,
    required this.controller,
    required this.textFieldKey,
    required this.isLongEnough,
    required this.hasText,
    required this.enableLoading,
    required this.onGoPressed,
    required this.isMovie,
    required this.hasActiveFilters,
    required this.onFiltersPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasText ? context.appColors.accent : context.appColors.accent.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.accent.withValues(alpha: hasText ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            key: textFieldKey,
            autofocus: false,
            showCursor: true,
            maxLines: 4,
            minLines: 3,
            controller: controller,
            cursorColor: context.appColors.accent,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
            decoration: InputDecoration(
              hintText: isMovie ? "hero_hint_movie".tr() : "hero_hint_show".tr(),
              hintStyle: TextStyle(
                fontSize: 15,
                color: context.appColors.textTertiary,
                height: 1.5,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              border: InputBorder.none,
            ),
          ),
          // Filters + GO button row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _FiltersButton(
                  hasActiveFilters: hasActiveFilters,
                  onPressed: onFiltersPressed,
                ),
                const Spacer(),
                _GoButton(
                  isLongEnough: isLongEnough,
                  enableLoading: enableLoading,
                  onPressed: onGoPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback? onPressed;

  const _FiltersButton({required this.hasActiveFilters, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters ? context.appColors.accent.withValues(alpha: 0.6) : context.appColors.border,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: hasActiveFilters ? context.appColors.accent : Colors.grey[400], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'filters'.tr(),
                    style: TextStyle(
                      color: hasActiveFilters ? context.appColors.accent : Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (hasActiveFilters)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: context.appColors.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  final bool isLongEnough;
  final bool enableLoading;
  final VoidCallback? onPressed;

  const _GoButton({
    required this.isLongEnough,
    required this.enableLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = isLongEnough && !enableLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      decoration: BoxDecoration(
        gradient: isReady
            ? LinearGradient(
                colors: [context.appColors.accent, context.appColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isReady ? null : context.appColors.inactive,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: context.appColors.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isReady ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: enableLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "go".tr(),
                          style: TextStyle(
                            color: isReady ? Colors.white : context.appColors.textTertiary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isReady ? Colors.white : context.appColors.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
