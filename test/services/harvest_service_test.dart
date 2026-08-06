// Unit tests for lib/services/harvest_service.dart.

import 'package:cocoa_supply/services/harvest_service.dart';
import 'package:cocoa_supply/models/harvest_model.dart';
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

  group('getHarvests', () {
    test('returns parsed harvests on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/harvests');
        return jsonResponse([
          {'harvest_id': 1, 'farm_name': 'ไร่โกโก้พรีเมียม'},
        ], 200);
      });

      final harvests = await HarvestService(client: client).getHarvests();

      expect(harvests, hasLength(1));
      expect(harvests.first.farmName, 'ไร่โกโก้พรีเมียม');
    });

    test('falls back to cache when the request throws', () async {
      SharedPreferences.setMockInitialValues({
        'harvest_data': '[{"harvest_id":"cached"}]',
      });
      final client = MockClient((request) async => throw Exception('offline'));

      final harvests = await HarvestService(client: client).getHarvests();

      expect(harvests, hasLength(1));
      expect(harvests.first.harvestId, 'cached');
    });
  });

  group('saveHarvest', () {
    test('posts the harvest payload', () async {
      Map<String, dynamic>? posted;
      final client = MockClient((request) async {
        posted = {'method': request.method};
        return jsonResponse({}, 200);
      });

      await HarvestService(client: client).saveHarvest(Harvest(harvestId: '1'));

      expect(posted?['method'], 'POST');
    });
  });

  group('deleteHarvest', () {
    test('sends a DELETE request for the given id', () async {
      var deletedPath = '';
      final client = MockClient((request) async {
        deletedPath = request.url.path;
        return http.Response('', 200);
      });

      await HarvestService(client: client).deleteHarvest('7');

      expect(deletedPath, '/harvests/7');
    });
  });
}
