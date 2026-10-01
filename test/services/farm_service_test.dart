// Unit tests for lib/services/farm_service.dart.

import 'dart:convert';

import 'package:cocoa_supply/models/farm_model.dart';
import 'package:cocoa_supply/services/farm_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      // ServiceProvider's cache is backed by flutter_secure_storage (APP-2).
      SharedPreferences.setMockInitialValues({
        'farm_data': '[{"farm_id":"cached"}]',
      });
      FlutterSecureStorage.setMockInitialValues({
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
  group('ServiceProvider.uploadFile (farm photo)', () {
    test('posts the bytes as multipart field "image" with the bearer token', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'aaa.bbb.ccc'});
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return jsonResponse({'message': 'ok', 'image_url': 'https://r2.test/x.jpg'}, 200);
      });
      final provider = ServiceProvider(endpoint: '/farms', isRealApi: true, storageKey: 'farms', client: client);

      final result = await provider.uploadFile('farm-1/image', field: 'image', bytes: [1, 2, 3], filename: 'farm.jpg');

      expect(sent.method, 'POST');
      expect(sent.url.toString(), '$testBaseUrl/farms/farm-1/image');
      expect(sent.headers['Authorization'], 'Bearer aaa.bbb.ccc');
      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      final body = latin1.decode(sent.bodyBytes);
      expect(body, contains('name="image"; filename="farm.jpg"'));
      expect(result['image_url'], 'https://r2.test/x.jpg');
    });

    test("throws the server's own error message on rejection", () async {
      final client = MockClient((request) async => jsonResponse({'error': 'รองรับเฉพาะไฟล์ JPG, PNG หรือ WEBP'}, 415));
      final provider = ServiceProvider(endpoint: '/farms', isRealApi: true, storageKey: 'farms', client: client);

      await expectLater(
        provider.uploadFile('farm-1/image', field: 'image', bytes: [1], filename: 'x.gif'),
        throwsA('รองรับเฉพาะไฟล์ JPG, PNG หรือ WEBP'),
      );
    });
  });
}
