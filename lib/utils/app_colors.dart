import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Brand
  final Color accent;
  final Color accentDark;

  // Tonal elevation ramp (base -> cards -> elevated -> top)
  final Color background;
  final Color surface; // surface1 — cards
  final Color surface2; // chips / elevated fills
  final Color surface3; // top elevation / nested

  // Lines & inactive
  final Color border; // subtle hairline, used sparingly
  final Color borderSubtle;
  final Color hairline;
  final Color inactive; // disabled fills / inactive icons

  // Semantic text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Legacy alias (kept so existing references compile)
  final Color chip;

  const AppColors({
    required this.accent,
    required this.accentDark,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderSubtle,
    required this.hairline,
    required this.inactive,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.chip,
  });

  // ── True Black OLED ───────────────────────────────────────────────────────
  // Near-black base so poster art glows; a controlled elevation ramp instead of
  // one flat grey; subtle hairlines instead of heavy outlines.
  static const defaults = AppColors(
    accent: Color(0xFFF07A14),
    accentDark: Color(0xFFCF6608),
    background: Color(0xFF0A0A0B),
    surface: Color(0xFF1D1D21),
    surface2: Color(0xFF27272C),
    surface3: Color(0xFF313137),
    border: Color(0xFF34343B),
    borderSubtle: Color(0xFF27272C),
    hairline: Color(0xFF242429),
    inactive: Color(0xFF44444C),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFF9A9AA0),
    textTertiary: Color(0xFF6A6A70),
    chip: Color(0xFF202023),
  );

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentDark,
    Color? background,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? borderSubtle,
    Color? hairline,
    Color? inactive,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? chip,
  }) =>
      AppColors(
        accent: accent ?? this.accent,
        accentDark: accentDark ?? this.accentDark,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        surface3: surface3 ?? this.surface3,
        border: border ?? this.border,
        borderSubtle: borderSubtle ?? this.borderSubtle,
        hairline: hairline ?? this.hairline,
        inactive: inactive ?? this.inactive,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
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
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
