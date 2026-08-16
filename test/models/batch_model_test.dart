// Unit tests for lib/models/batch_model.dart.
//
// Pure JSON round-trip tests: no mocking needed. These guard the wire
// contract with the Go backend (snake_case keys, string/num coercion).

import 'package:cocoa_supply/models/batch_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Batch.fromJson', () {
    test('parses a fully-populated payload', () {
      final batch = Batch.fromJson({
        'batch_id': 1,
        'processing_station_id': 2,
        'processing_station_name': 'ศูนย์แปรรูปแม่จัน',
        'origin': 'ริมรั้ว',
        'name': 'ริมรั้ว (30 เม.ย. 2569)',
        'notes': 'ฝักบางตัวเน่า',
        'quantity_kg': '5.0',
        'created_at': '2026-01-11T13:40:00.000Z',
        'updated_at': '2026-01-11T13:40:00.000Z',
      });

      expect(batch.batchId, '1');
      expect(batch.processingStationId, '2');
      expect(batch.processingStationName, 'ศูนย์แปรรูปแม่จัน');
      expect(batch.origin, 'ริมรั้ว');
      expect(batch.quantityKg, 5.0);
      expect(batch.createdAt, DateTime.parse('2026-01-11T13:40:00.000Z'));
    });

    test('tolerates a numeric quantity_kg instead of a string', () {
      final batch = Batch.fromJson({'quantity_kg': 5.5});
      expect(batch.quantityKg, 5.5);
    });

    test('all fields are null when json is empty', () {
      final batch = Batch.fromJson({});
      expect(batch.batchId, isNull);
      expect(batch.quantityKg, isNull);
      expect(batch.createdAt, isNull);
    });
  });

  group('Batch.toJson', () {
    test('round-trips through fromJson/toJson', () {
      final original = Batch(
        batchId: '1',
        processingStationId: '2',
        origin: 'ริมรั้ว',
        quantityKg: 5.0,
        createdAt: DateTime.parse('2026-01-11T13:40:00.000Z'),
      );

      final roundTripped = Batch.fromJson(original.toJson());

      expect(roundTripped.batchId, original.batchId);
      expect(roundTripped.processingStationId, original.processingStationId);
      expect(roundTripped.origin, original.origin);
      expect(roundTripped.quantityKg, original.quantityKg);
      expect(roundTripped.createdAt, original.createdAt);
    });

    test('serializes null fields as null, not omitted', () {
      final json = Batch().toJson();
      expect(json['batch_id'], isNull);
      expect(json.containsKey('batch_id'), isTrue);
    });
  });
}
