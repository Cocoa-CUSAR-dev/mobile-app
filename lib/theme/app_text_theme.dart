import 'package:flutter/material.dart';

/// Central text scale for the app. Material 3's default TextTheme sizes
/// (bodyLarge 16, bodyMedium 14, bodySmall 12, ...) are tuned for dense
/// desktop/phone UIs, not for elderly readability -- this bumps the
/// commonly-used roles up a few points and keeps the scale consistent, so
/// screens that just use `Theme.of(context).textTheme.bodyMedium` (etc.)
/// get a readable size without every screen picking its own fontSize.
///
/// This does not migrate the ~100 existing call sites that already pass an
/// explicit `TextStyle(fontSize: ...)` -- those were sized deliberately
/// per screen and auditing every one of them for whether the value is
/// "content" vs. "just needs to be bigger" is out of scope here. New/
/// redesigned widgets (this issue's siblings under #32) should prefer
/// reading from this scale instead of hardcoding another one-off size.
class AppTextTheme {
  AppTextTheme._();

  static const TextTheme scale = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );
}
