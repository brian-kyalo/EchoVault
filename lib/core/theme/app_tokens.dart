import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B1118);
  static const surface = Color(0xFF15212D);
  static const foreground = Color(0xFFF0F5F9);
  static const muted = Color(0xFFB0C2D0);
  static const accent = Color(0xFF80E8D1);
  static const secondary = Color(0xFFCCBEFF);
  static const outline = Color(0xFF506475);
  static const error = Color(0xFFFFB4AB);
}

abstract final class AppSpacing {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const extraLarge = 32.0;
  static const section = 48.0;
}

abstract final class AppRadius {
  static const control = 16.0;
  static const panel = 24.0;
}

abstract final class AppDurations {
  static const dialogTransition = Duration(milliseconds: 180);
}

abstract final class AppTypography {
  // Platform fonts avoid a network dependency and remain readable offline.
  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 40,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.2,
    ),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 17, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, height: 1.5),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w600,
    ),
  );
}
