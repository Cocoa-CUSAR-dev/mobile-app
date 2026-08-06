// Unit tests for lib/services/dynamic_api_service.dart.
//
// Notable finding pinned by these tests: fetchData() and submitData() build
// their ServiceProvider without `isRealApi: true` (unlike fetchConstants()
// and every concrete *Service class, which all set it explicitly), so both
// methods always run ServiceProvider's local/mock branch — they never call
// the injected http.Client at all, regardless of environment. In mock mode,
// fetchData only ever returns whatever is already cached in
// SharedPreferences (empty on a fresh install), and submitData's `isEdit:
// true` path (putData) doesn't persist anything either. If DynamicApiService
// is meant to reach the real backend for dynamic-form submissions, this
// looks like a missing `isRealApi: true` rather than intended behavior —
// worth a human confirming intent.

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

  group('fetchData (documented current behavior: mock/local mode only)', () {
    test('never calls the network and returns cached rows when present', () async {
      SharedPreferences.setMockInitialValues({
        'farm_data': '[{"farm_id":1}]',
      });
      var networkCalled = false;
      final client = MockClient((request) async {
        networkCalled = true;
        return jsonResponse([], 200);
      });

      final rows = await DynamicApiService(client: client).fetchData('farm');

      expect(networkCalled, isFalse);
      expect(rows, [
        {'farm_id': 1},
      ]);
    });

    test('returns an empty list when nothing is cached yet', () async {
      final rows = await DynamicApiService().fetchData('farm');
      expect(rows, isEmpty);
    });
  });

  group('submitData (documented current behavior: mock/local mode only)', () {
    test('isEdit:false appends the payload to local storage under <tableName>_data', () async {
      var networkCalled = false;
      final client = MockClient((request) async {
        networkCalled = true;
        return jsonResponse({}, 200);
      });

      await DynamicApiService(client: client).submitData('farm', {'farm_id': 1});

      expect(networkCalled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farm_data'), '[{"farm_id":1}]');
    });

    test('isEdit:true does not persist anything locally (putData mock branch is a no-op)', () async {
      await DynamicApiService().submitData('farm', {'farm_id': 1}, isEdit: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farm_data'), isNull);
    });
  });

  group('fetchConstants (the one method that does set isRealApi: true)', () {
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
