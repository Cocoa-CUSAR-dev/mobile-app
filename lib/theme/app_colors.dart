import 'package:flutter/material.dart';

/// Single source of truth for the app's brand colors. Every widget that
/// used to hardcode the cacao-brown literal directly now reads it from
/// here, so the palette can be adjusted in one place.
class AppColors {
  AppColors._();

  /// Cacao-brown brand color -- app bar, primary buttons, selected states.
  static const Color primary = Color(0xFF794C46);

  /// primary at ~53% opacity, used for placeholder/disabled input borders.
  static const Color primaryMuted = Color(0x88794C46);

  /// primary at ~10% opacity, used for subtle tinted fills (e.g. a filled
  /// GIS/location preview) where the full primary would be too heavy.
  static const Color primaryFaint = Color(0x1A794C46);

  /// Warm terracotta accent -- for badges, highlights, and other small
  /// details that need to stand out from the primary brown without
  /// clashing with it.
  static const Color accent = Color(0xFFC97B4A);

  /// Warm off-white background, slightly less stark than pure white/grey.
  static const Color background = Color(0xFFFAF6F3);

  /// Neutral card/input fill, unchanged from the previous literal.
  static const Color surface = Color(0xFFF8F8F8);
}
