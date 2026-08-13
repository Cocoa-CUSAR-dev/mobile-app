// Unit tests for lib/services/farm_service.dart.

import 'package:cocoa_supply/models/farm_model.dart';
import 'package:cocoa_supply/services/farm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getFarms', () {
    test('returns parsed farms on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/farms');
        return jsonResponse([
          {'farm_id': 1, 'farm_name': 'ไร่โกโก้พรีเมียม'},
        ], 200);
      });

      final farms = await FarmService(client: client).getFarms();

      expect(farms, hasLength(1));
      expect(farms.first.farmName, 'ไร่โกโก้พรีเมียม');
    });

    test('falls back to cache on a non-200 response', () async {
      SharedPreferences.setMockInitialValues({
        'farm_data': '[{"farm_id":"cached"}]',
      });
      final client = MockClient((request) async => http.Response('error', 500));

      final farms = await FarmService(client: client).getFarms();

      expect(farms, hasLength(1));
      expect(farms.first.farmId, 'cached');
    });

    test('applies queryParams to the cache key so different filters do not collide', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'farm_id': request.url.queryParameters['hub_id']},
        ], 200);
      });
      final service = FarmService(client: client);

      final hub1 = await service.getFarms(queryParams: {'hub_id': '1'});
      final hub2 = await service.getFarms(queryParams: {'hub_id': '2'});

      expect(hub1.first.farmId, '1');
      expect(hub2.first.farmId, '2');
    });
  });

  group('getFarmById', () {
    test('returns the matching farm from getFarms', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'farm_id': 1, 'farm_name': 'A'},
          {'farm_id': 2, 'farm_name': 'B'},
        ], 200);
      });

      final farm = await FarmService(client: client).getFarmById('2');

      expect(farm?.farmName, 'B');
    });
  });

  group('saveFarm', () {
    test('rejects a farm whose id already exists', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'farm_id': 1},
        ], 200);
      });
      final service = FarmService(client: client);

      await expectLater(
        service.saveFarm(Farm(farmId: '1')),
        throwsA(isA<Exception>()),
      );
    });

    test('posts the new farm when the id does not already exist', () async {
      var posted = false;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          posted = true;
          return jsonResponse({'farm_id': '2'}, 200);
        }
        return jsonResponse([], 200);
      });

      await FarmService(client: client).saveFarm(Farm(farmId: '2', farmName: 'New'));

      expect(posted, isTrue);
    });
  });
}
