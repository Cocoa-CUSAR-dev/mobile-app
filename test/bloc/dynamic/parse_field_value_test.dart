import 'package:cocoa_supply/bloc/dynamic/parse_field_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFieldValue', () {
    test('returns null for a null value regardless of inputType', () {
      expect(parseFieldValue(null, 'INT'), isNull);
      expect(parseFieldValue(null, 'VARCHAR'), isNull);
      expect(parseFieldValue(null, null), isNull);
    });

    test('returns null for an empty-string value', () {
      expect(parseFieldValue('', 'VARCHAR'), isNull);
      expect(parseFieldValue('', 'INT'), isNull);
    });

    group('INT', () {
      test('parses a numeric string to an int', () {
        expect(parseFieldValue('42', 'INT'), 42);
      });

      test('a non-numeric string fails to parse to null', () {
        // int.tryParse's own behavior -- documented here since a caller
        // might reasonably expect an exception instead of a silent null.
        expect(parseFieldValue('not a number', 'INT'), isNull);
      });
    });

    group('FLOAT', () {
      test('parses a decimal string to a double', () {
        expect(parseFieldValue('3.14', 'FLOAT'), 3.14);
      });

      test('parses a whole-number string to a double', () {
        expect(parseFieldValue('5', 'FLOAT'), 5.0);
      });

      test('a non-numeric string fails to parse to null', () {
        expect(parseFieldValue('abc', 'FLOAT'), isNull);
      });
    });

    group('BOOLEAN', () {
      test('a real bool value passes through unchanged', () {
        expect(parseFieldValue(true, 'BOOLEAN'), isTrue);
        expect(parseFieldValue(false, 'BOOLEAN'), isFalse);
      });

      test('the string "true" (any case) becomes true', () {
        expect(parseFieldValue('true', 'BOOLEAN'), isTrue);
        expect(parseFieldValue('TRUE', 'BOOLEAN'), isTrue);
        expect(parseFieldValue('True', 'BOOLEAN'), isTrue);
      });

      test('any other string becomes false', () {
        expect(parseFieldValue('false', 'BOOLEAN'), isFalse);
        expect(parseFieldValue('yes', 'BOOLEAN'), isFalse);
        expect(parseFieldValue('1', 'BOOLEAN'), isFalse);
      });
    });

    group('pass-through types (VARCHAR, OPTION, DATE, DATETIME, GEODATA, unknown)', () {
      test('a plain string value passes through as a string', () {
        expect(parseFieldValue('hello', 'VARCHAR'), 'hello');
      });

      test('a non-string value is stringified', () {
        expect(parseFieldValue(42, 'VARCHAR'), '42');
      });

      test('an OPTION value (the selected choice id) passes through as-is', () {
        expect(parseFieldValue('choice-uuid-123', 'OPTION'), 'choice-uuid-123');
      });

      test('an unrecognized inputType still falls through to string conversion', () {
        expect(parseFieldValue('2026-01-01', 'DATE'), '2026-01-01');
        expect(parseFieldValue('something', 'UNKNOWN_TYPE'), 'something');
      });
    });
  });
}
