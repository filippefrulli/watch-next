import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color accent;
  final Color accentDark;
  final Color background;
  final Color surface;
  final Color border;
  final Color borderSubtle;
  final Color inactive;
  final Color chip;

  const AppColors({
    required this.accent,
    required this.accentDark,
    required this.background,
    required this.surface,
    required this.border,
    required this.borderSubtle,
    required this.inactive,
    required this.chip,
  });

  static const defaults = AppColors(
    accent:       Color(0xFFFF6B35), // lighter tomato-orange
    accentDark:   Color(0xFFE05525), // darker shade
    background:   Color(0xFF111111), // darker charcoal
    surface:      Color(0xFF262626), // dark grey card
    border:       Color(0xFF333333), // subtle grey border
    borderSubtle: Color(0xFF2E2E2E),
    inactive:     Color(0xFF2E2E2E),
    chip:         Color(0xFF2E2E2E),
  );

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentDark,
    Color? background,
    Color? surface,
    Color? border,
    Color? borderSubtle,
    Color? inactive,
    Color? chip,
  }) =>
      AppColors(
        accent: accent ?? this.accent,
        accentDark: accentDark ?? this.accentDark,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        border: border ?? this.border,
        borderSubtle: borderSubtle ?? this.borderSubtle,
        inactive: inactive ?? this.inactive,
        chip: chip ?? this.chip,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
