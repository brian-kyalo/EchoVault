import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      secondary: AppColors.secondary,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.outline,
      error: AppColors.error,
      onError: AppColors.background,
    ),
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
    ),
  );
}
