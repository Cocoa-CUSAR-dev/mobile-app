// Unit tests for lib/models/harvest_model.dart.
//
// Note: toJson intentionally drops a few read-only/join-only fields
// (grade_description, is_clean, weight_gram_per_pod) that fromJson accepts —
// this is existing behavior in the model (fields are populated by a SQL
// JOIN on read, not sent back on write), so the round-trip test only
// checks the fields toJson actually emits.

import 'package:cocoa_supply/models/harvest_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Harvest.fromJson', () {
    test('parses a fully-populated payload', () {
      final harvest = Harvest.fromJson({
        'harvest_id': 1,
        'hub_id': 2,
        'farm_id': 3,
        'farm_name': 'ไร่โกโก้พรีเมียม',
        'plot_id': 4,
        'grade_code': 'A',
        'quantity_kg': '150.50',
        'is_clean': true,
        'batch_id': 5,
        'collection_id': 6,
        'harvest_date': '2026-01-11T00:00:00.000Z',
      });

      expect(harvest.harvestId, '1');
      expect(harvest.farmName, 'ไร่โกโก้พรีเมียม');
      expect(harvest.quantityKg, 150.5);
      expect(harvest.isClean, isTrue);
      expect(harvest.harvestDate, DateTime.parse('2026-01-11T00:00:00.000Z'));
    });

    test('all fields are null when json is empty', () {
      final harvest = Harvest.fromJson({});
      expect(harvest.harvestId, isNull);
      expect(harvest.quantityKg, isNull);
    });
  });

  group('Harvest.toJson', () {
    test('round-trips the fields it emits through fromJson', () {
      final original = Harvest(
        harvestId: '1',
        hubId: '2',
        farmId: '3',
        plotId: '4',
        gradeCode: 'A',
        quantityKg: 150.5,
        batchId: '5',
        collectionId: '6',
        harvestDate: DateTime.parse('2026-01-11T00:00:00.000Z'),
      );

      final roundTripped = Harvest.fromJson(original.toJson());

      expect(roundTripped.harvestId, original.harvestId);
      expect(roundTripped.hubId, original.hubId);
      expect(roundTripped.farmId, original.farmId);
      expect(roundTripped.gradeCode, original.gradeCode);
      expect(roundTripped.quantityKg, original.quantityKg);
      expect(roundTripped.harvestDate, original.harvestDate);
    });
  });
}
