// Unit tests for lib/services/hub_service.dart.

import 'package:cocoa_supply/models/hub_model.dart';
import 'package:cocoa_supply/services/hub_service.dart';
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

  group('fetchAll', () {
    test('returns parsed hubs on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/hubs');
        return jsonResponse([
          {'hub_id': 1, 'hub_name': 'จุดรับซื้อกลาง'},
        ], 200);
      });

      final hubs = await HubService(client: client).fetchAll();

      expect(hubs, hasLength(1));
      expect(hubs.first.hubName, 'จุดรับซื้อกลาง');
    });
  });

  group('fetchById', () {
    test('returns the matching hub', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'hub_id': 1, 'hub_name': 'A'},
          {'hub_id': 2, 'hub_name': 'B'},
        ], 200);
      });

      final hub = await HubService(client: client).fetchById('2');

      expect(hub?.hubName, 'B');
    });

    test('returns null when no hub matches the id', () async {
      final client = MockClient((request) async => jsonResponse([], 200));

      final hub = await HubService(client: client).fetchById('missing');

      expect(hub, isNull);
    });
  });

  group('save', () {
    test('rejects a hub whose id already exists', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'hub_id': 1},
        ], 200);
      });

      await expectLater(
        HubService(client: client).save(Hub(hubId: '1')),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('delete', () {
    test('sends a DELETE request for the given id', () async {
      var deletedId = '';
      final client = MockClient((request) async {
        if (request.method == 'DELETE') {
          deletedId = request.url.pathSegments.last;
          return http.Response('', 200);
        }
        return jsonResponse([], 200);
      });

      await HubService(client: client).delete('42');

      expect(deletedId, '42');
    });
  });
}
