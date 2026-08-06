// Unit tests for lib/services/util_service.dart.

import 'package:cocoa_supply/services/util_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UtilService.formatThaiDate', () {
    test('formats a date with the Thai month name and Buddhist-era year', () {
      final formatted = UtilService.formatThaiDate(DateTime(2026, 1, 11));
      expect(formatted, '11 มกราคม 2569');
    });

    test('formats December correctly (month-index boundary)', () {
      final formatted = UtilService.formatThaiDate(DateTime(2025, 12, 31));
      expect(formatted, '31 ธันวาคม 2568');
    });
  });
}
