// Unit tests for lib/models/plot_model.dart.

import 'package:cocoa_supply/models/plot_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Plot.fromJson', () {
    test('parses a fully-populated payload', () {
      final plot = Plot.fromJson({
        'plot_id': 1,
        'farm_id': 2,
        'plot_name': 'แปลง 1',
        'total_area': '5.5',
        'land_ownership': 'เจ้าของ',
        'cocoa_planted_area': '4.0',
        'has_chemical_use': true,
        'found_date': '2026-01-11T00:00:00.000Z',
      });

      expect(plot.plotId, '1');
      expect(plot.farmId, '2');
      expect(plot.plotName, 'แปลง 1');
      expect(plot.totalArea, 5.5);
      expect(plot.cocoaPlantedArea, 4.0);
      expect(plot.hasChemicalUse, isTrue);
    });

    test('all fields are null when json is empty', () {
      final plot = Plot.fromJson({});
      expect(plot.plotId, isNull);
      expect(plot.totalArea, isNull);
    });
  });

  group('Plot.toJson', () {
    test('round-trips through fromJson/toJson', () {
      final original = Plot(
        plotId: '1',
        farmId: '2',
        plotName: 'แปลง 1',
        totalArea: 5.5,
        hasChemicalUse: false,
        foundDate: DateTime.parse('2026-01-11T00:00:00.000Z'),
      );

      final roundTripped = Plot.fromJson(original.toJson());

      expect(roundTripped.plotId, original.plotId);
      expect(roundTripped.farmId, original.farmId);
      expect(roundTripped.plotName, original.plotName);
      expect(roundTripped.totalArea, original.totalArea);
      expect(roundTripped.hasChemicalUse, original.hasChemicalUse);
      expect(roundTripped.foundDate, original.foundDate);
    });
  });
}
