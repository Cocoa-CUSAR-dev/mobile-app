// Guards the two things about AppTheme that fail silently: a text style
// that renders in the wrong font, and a ColorScheme pair that is legible
// in review but not on a phone in daylight. Neither shows up in
// `flutter analyze`, and neither breaks any existing test.

import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';
import 'package:cocoa_supply/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Thai font reaches the text that needs it', () {
    testWidgets('AppBar titles render in the looped face', (tester) async {
      // ThemeData.fontFamily only applies to the TextTheme ThemeData
      // builds. AppBarTheme.titleTextStyle is resolved before
      // textTheme.titleLarge is ever consulted, so a style taken from the
      // raw AppTextTheme.scale would fall back to the platform default --
      // losing the looped face on the largest Thai text on every screen,
      // with nothing failing anywhere to say so.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: AppBar(title: const Text('ข้อมูลส่วนตัว')),
            body: const Text('เนื้อหา'),
          ),
        ),
      );

      final titleStyle =
          DefaultTextStyle.of(tester.element(find.text('ข้อมูลส่วนตัว'))).style;
      final bodyStyle = DefaultTextStyle.of(tester.element(find.text('เนื้อหา'))).style;

      expect(titleStyle.fontFamily, AppTextTheme.fontFamily);
      expect(bodyStyle.fontFamily, AppTextTheme.fontFamily);
    });

    test('every role in the scale carries the font', () {
      // The scale is read directly in places ThemeData never touches, so
      // the font has to be on the styles themselves.
      final scale = AppTextTheme.scale;
      final roles = <String, TextStyle?>{
        'headlineLarge': scale.headlineLarge,
        'headlineMedium': scale.headlineMedium,
        'headlineSmall': scale.headlineSmall,
        'titleLarge': scale.titleLarge,
        'titleMedium': scale.titleMedium,
        'titleSmall': scale.titleSmall,
        'bodyLarge': scale.bodyLarge,
        'bodyMedium': scale.bodyMedium,
        'bodySmall': scale.bodySmall,
        'labelLarge': scale.labelLarge,
        'labelMedium': scale.labelMedium,
        'labelSmall': scale.labelSmall,
      };

      roles.forEach((role, style) {
        expect(style?.fontFamily, AppTextTheme.fontFamily, reason: '$role lost the font');
      });
    });
  });

  group('ColorScheme pairs are legible', () {
    // 4.5:1 is WCAG AA for normal-size text. Worth holding to for an
    // audience reading Thai outdoors, often with older eyes.
    const aa = 4.5;

    test('onPrimary on primary', () {
      final cs = AppTheme.light.colorScheme;
      expect(contrastRatio(cs.onPrimary, cs.primary), greaterThanOrEqualTo(aa));
    });

    test('onSecondary on secondary', () {
      // secondary is overridden to AppColors.accent; without overriding
      // onSecondary too it stays the white derived for the seed, which is
      // 3.27:1 against accent.
      final cs = AppTheme.light.colorScheme;
      expect(contrastRatio(cs.onSecondary, cs.secondary), greaterThanOrEqualTo(aa));
    });
  });

  test('surface is read from AppColors, not re-declared', () {
    expect(AppTheme.light.colorScheme.surface, AppColors.surface);
  });
}
