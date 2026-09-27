import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';

/// Central ThemeData for the app -- was previously built inline in
/// main.dart with just a primarySwatch, leaving every screen to hardcode
/// its own brown color literal instead of reading it from a shared
/// ColorScheme.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      // Overriding secondary without this leaves onSecondary as the white
      // fromSeed derived for the old value: 3.27:1 against accent, under
      // WCAG AA. Black is 6.42:1. Nothing reads the pair yet, but accent
      // is designated for the #40 task-card badges, and this audience is
      // reading Thai text outdoors.
      onSecondary: Colors.black,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextTheme.fontFamily,
      textTheme: AppTextTheme.scale,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTextTheme.scale.titleLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
