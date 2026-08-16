// Unit tests for lib/models/hub_model.dart.

import 'package:cocoa_supply/models/hub_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hub.fromJson', () {
    test('parses a fully-populated payload including nested harvests', () {
      final hub = Hub.fromJson({
        'hub_id': 1,
        'hub_name': 'จุดรับซื้อกลาง',
        'found_date': '2026-01-11T00:00:00.000Z',
        'address_detail': '111/55',
        'zip_code': '11000',
        'contact_name': 'สมชาย โกโก้ดี',
        'phone_number': '0812345678',
        'harvests': [
          {'harvest_id': 1, 'farm_name': 'ไร่โกโก้พรีเมียม'},
        ],
      });

      expect(hub.hubId, '1');
      expect(hub.hubName, 'จุดรับซื้อกลาง');
      expect(hub.harvests, hasLength(1));
      expect(hub.harvests!.first.farmName, 'ไร่โกโก้พรีเมียม');
    });

    test('harvests is null when absent from the payload', () {
      final hub = Hub.fromJson({'hub_id': 1});
      expect(hub.harvests, isNull);
    });

    test('all fields are null when json is empty', () {
      final hub = Hub.fromJson({});
      expect(hub.hubId, isNull);
      expect(hub.harvests, isNull);
    });
  });

  group('Hub.toJson', () {
    test('round-trips scalar fields through fromJson/toJson', () {
      final original = Hub(
        hubId: '1',
        hubName: 'จุดรับซื้อกลาง',
        foundDate: DateTime.parse('2026-01-11T00:00:00.000Z'),
      );

      final roundTripped = Hub.fromJson(original.toJson());

      expect(roundTripped.hubId, original.hubId);
      expect(roundTripped.hubName, original.hubName);
      expect(roundTripped.foundDate, original.foundDate);
    });
  });
}
