// Unit tests for lib/models/farm_model.dart.

import 'package:cocoa_supply/models/farm_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Farm.fromJson', () {
    test('parses a fully-populated payload including nested plots', () {
      final farm = Farm.fromJson({
        'farm_id': 10,
        'farm_name': 'ไร่โกโก้พรีเมียม',
        'hub_id': 3,
        'found_date': '2026-01-11T00:00:00.000Z',
        'total_area': '12.5',
        'address_detail': '111/55',
        'zip_code': '11000',
        'contact_name': 'สมชาย โกโก้ดี',
        'phone_number': '0812345678',
        'plots': [
          {'plot_id': 1, 'plot_name': 'แปลง 1'},
        ],
      });

      expect(farm.farmId, '10');
      expect(farm.farmName, 'ไร่โกโก้พรีเมียม');
      expect(farm.totalArea, 12.5);
      expect(farm.plots, hasLength(1));
      expect(farm.plots!.first.plotName, 'แปลง 1');
    });

    test('plots is null when absent from the payload', () {
      final farm = Farm.fromJson({'farm_id': 1});
      expect(farm.plots, isNull);
    });

    test('all fields are null when json is empty', () {
      final farm = Farm.fromJson({});
      expect(farm.farmId, isNull);
      expect(farm.totalArea, isNull);
      expect(farm.plots, isNull);
      expect(farm.imageUrl, isNull);
    });

    test('reads the presigned image_url', () {
      final farm = Farm.fromJson({'farm_id': 1, 'image_url': 'https://r2.test/farms/1/a.jpg?sig=x'});
      expect(farm.imageUrl, 'https://r2.test/farms/1/a.jpg?sig=x');
    });

    test('image_url null means the farm has no photo', () {
      final farm = Farm.fromJson({'farm_id': 1, 'image_url': null});
      expect(farm.imageUrl, isNull);
    });
  });

  group('Farm.toJson', () {
    test('round-trips scalar fields through fromJson/toJson', () {
      final original = Farm(
        farmId: '10',
        farmName: 'ไร่โกโก้พรีเมียม',
        totalArea: 12.5,
        foundDate: DateTime.parse('2026-01-11T00:00:00.000Z'),
      );

      final roundTripped = Farm.fromJson(original.toJson());

      expect(roundTripped.farmId, original.farmId);
      expect(roundTripped.farmName, original.farmName);
      expect(roundTripped.totalArea, original.totalArea);
      expect(roundTripped.foundDate, original.foundDate);
    });

    test('round-trips imageUrl, so cached farm lists keep their photo', () {
      final roundTripped = Farm.fromJson(Farm(farmId: '1', imageUrl: 'https://r2.test/x.jpg').toJson());
      expect(roundTripped.imageUrl, 'https://r2.test/x.jpg');
    });

    test('omits the plots key when plots is null', () {
      final json = Farm(farmId: '1').toJson();
      expect(json.containsKey('plots'), isFalse);
    });
  });
}
