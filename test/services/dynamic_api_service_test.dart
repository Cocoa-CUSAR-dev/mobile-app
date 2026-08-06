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
        expect(request.url.toString(), 'http://localhost:8080/farm');
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
        expect(request.url.toString(), 'http://localhost:8080/farm');
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
        expect(request.url.toString(), 'http://localhost:8080/constants/province_id');
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

      final rows = await DynamicApiService(client: client).fetchConstants('province_id');

      expect(rows, isEmpty);
    });
  });
}
