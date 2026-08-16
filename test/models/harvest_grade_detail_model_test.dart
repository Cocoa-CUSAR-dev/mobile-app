// Unit tests for lib/models/harvest_grade_detail_model.dart.

import 'package:cocoa_supply/models/harvest_grade_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HarvestGradeDetail.fromJson', () {
    test('parses a fully-populated payload', () {
      final detail = HarvestGradeDetail.fromJson({
        'harvest_id': 5,
        'grade_code': 'A',
        'quantity_kg': '150.50',
        'description': 'มีฝักเสียบางอัน',
        'is_clean': true,
        'is_appropriate_size': true,
        'weight_gram_per_pod': '25.0',
        'is_sprout': false,
        'is_dry': true,
        'is_shriveled': false,
        'cut_test_result': 'เมล็ดมีสภาพดี',
        'created_at': '2026-01-11T00:00:00.000Z',
        'updated_at': '2026-01-11T00:00:00.000Z',
      });

      expect(detail.harvestId, '5');
      expect(detail.gradeCode, 'A');
      expect(detail.quantityKg, 150.50);
      expect(detail.isClean, isTrue);
      expect(detail.isSprout, isFalse);
      expect(detail.weightGramPerPod, 25.0);
    });

    test('all fields are null when json is empty', () {
      final detail = HarvestGradeDetail.fromJson({});
      expect(detail.harvestId, isNull);
      expect(detail.isClean, isNull);
      expect(detail.quantityKg, isNull);
    });
  });

  group('HarvestGradeDetail.toJson', () {
    test('round-trips through fromJson/toJson', () {
      final original = HarvestGradeDetail(
        harvestId: '5',
        gradeCode: 'A',
        quantityKg: 150.5,
        isClean: true,
        isSprout: false,
      );

      final roundTripped = HarvestGradeDetail.fromJson(original.toJson());

      expect(roundTripped.harvestId, original.harvestId);
      expect(roundTripped.gradeCode, original.gradeCode);
      expect(roundTripped.quantityKg, original.quantityKg);
      expect(roundTripped.isClean, original.isClean);
      expect(roundTripped.isSprout, original.isSprout);
    });
  });
}
