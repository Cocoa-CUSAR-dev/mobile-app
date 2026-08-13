// Unit tests for lib/services/profile_service.dart (AuthService).

import 'package:cocoa_supply/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getProfile', () {
    test('returns a parsed Profile on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/auth/me/');
        return jsonResponse({
          'user_id': 1,
          'first_name': 'สมชาย',
          'last_name': 'โกโก้ดี',
          'roles': ['farmer'],
        }, 200);
      });

      final profile = await AuthService(client: client).getProfile();

      expect(profile?.fullName, 'สมชาย โกโก้ดี');
      expect(profile?.roles, ['farmer']);
    });

    test('rethrows when the request fails', () async {
      final client = MockClient((request) async => jsonResponse({'error': 'unauthorized'}, 401));

      await expectLater(
        AuthService(client: client).getProfile(),
        throwsA(anything),
      );
    });
  });
}
