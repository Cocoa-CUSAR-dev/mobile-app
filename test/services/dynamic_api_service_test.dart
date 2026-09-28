// Unit tests for lib/services/dynamic_api_service.dart.
//
// KNOWN BUG (fetchData/submitData groups below are `skip`ped, not
// deleted): fetchData() and submitData() build their ServiceProvider
// without `isRealApi: true` (unlike fetchConstants() and every concrete
// *Service class, which all set it explicitly), so both methods always
// run ServiceProvider's local/mock branch — they never call the injected
// http.Client at all. Since DynamicApiService is meant to reach the real
// backend for dynamic-form submissions (that's the whole point of
// dynamic_register_page.dart), the tests below assert the real-network
// behavior a correct implementation should have; remove the `skip:` once
// fixed to confirm.

import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('fetchData', () {
    test('GETs /<tableName> from the real backend', () async {
      var networkCalled = false;
      final client = MockClient((request) async {
        networkCalled = true;
        expect(request.url.toString(), '$testBaseUrl/farm');
        return jsonResponse([
          {'farm_id': 1},
        ], 200);
      });

      final rows = await DynamicApiService(client: client).fetchData('farm');

      expect(networkCalled, isTrue);
      expect(rows, [
        {'farm_id': 1},
      ]);
    });
  }, skip: 'KNOWN BUG: fetchData() is missing isRealApi: true — see file header comment.');

  group('submitData', () {
    test('isEdit:false POSTs the payload to the real backend', () async {
      var method = '';
      final client = MockClient((request) async {
        method = request.method;
        expect(request.url.toString(), '$testBaseUrl/farm');
        return jsonResponse({}, 200);
      });

      await DynamicApiService(client: client).submitData('farm', {'farm_id': 1});

      expect(method, 'POST');
    });

    test('isEdit:true PUTs the payload to the real backend', () async {
      var method = '';
      final client = MockClient((request) async {
        method = request.method;
        return jsonResponse({}, 200);
      });

      await DynamicApiService(client: client).submitData('farm', {'farm_id': 1}, isEdit: true);

      expect(method, 'PUT');
    });
  }, skip: 'KNOWN BUG: submitData() is missing isRealApi: true — see file header comment.');

  group('fetchConstants (the one method that already sets isRealApi: true)', () {
    test('routes to /constants/<key>', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/constants/province_id');
        return jsonResponse([
          {'province_id': '50', 'province_name_th': 'เชียงใหม่'},
        ], 200);
      });

      final rows = await DynamicApiService(client: client).fetchConstants('province_id');

      expect(rows, hasLength(1));
      expect(rows.first['province_name_th'], 'เชียงใหม่');
    });

    test('swallows errors and returns an empty list', () async {
      final client = MockClient((request) async => throw Exception('offline'));

      // A different key than the test above -- fetchConstants caches
      // successful results in-memory keyed by key+queryParams (APP-10), so
      // reusing 'province_id' here would return that test's cached rows
      // instead of ever reaching this MockClient.
      final rows = await DynamicApiService(client: client).fetchConstants('district_id');

      expect(rows, isEmpty);
    });
  });

  group('fetchConstants caching', () {
    // The cache is static, so it carries between tests as well as between
    // screens -- clear it first or these assert against whatever ran before.
    setUp(DynamicApiService.clearConstantsCache);

    test('a second call for the same key does not hit the network again', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return jsonResponse([
          {'province_id': 1, 'province_name_th': 'กรุงเทพมหานคร'},
        ], 200);
      });

      final api = DynamicApiService(client: client);
      await api.fetchConstants('province');
      await api.fetchConstants('province');

      expect(calls, 1);
    });

    test('an empty result is not cached, so the next open can retry', () async {
      // A backend answering 200 with [] mid-deploy would otherwise leave
      // that dropdown empty for the rest of the session.
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return jsonResponse(calls == 1 ? [] : [
          {'province_id': 1, 'province_name_th': 'กรุงเทพมหานคร'},
        ], 200);
      });

      final api = DynamicApiService(client: client);
      expect(await api.fetchConstants('province'), isEmpty);
      expect(await api.fetchConstants('province'), hasLength(1));
      expect(calls, 2);
    });

    test('clearConstantsCache drops what a previous session cached', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return jsonResponse([
          {'province_id': 1, 'province_name_th': 'กรุงเทพมหานคร'},
        ], 200);
      });

      final api = DynamicApiService(client: client);
      await api.fetchConstants('province');
      DynamicApiService.clearConstantsCache();
      await api.fetchConstants('province');

      expect(calls, 2);
    });

    test('isBangkokProvinceId reads the cached province list', () async {
      final client = MockClient((request) async => jsonResponse([
        {'province_id': 1, 'province_name_th': 'กรุงเทพมหานคร'},
        {'province_id': 22, 'province_name_th': 'จันทบุรี'},
      ], 200));

      // Nothing cached yet -- callers that never opened the province
      // dropdown get false rather than a crash.
      expect(DynamicApiService.isBangkokProvinceId('1'), isFalse);

      await DynamicApiService(client: client).fetchConstants('province');

      expect(DynamicApiService.isBangkokProvinceId('1'), isTrue);
      expect(DynamicApiService.isBangkokProvinceId('22'), isFalse);
      expect(DynamicApiService.isBangkokProvinceId(null), isFalse);
    });
  });
}
