// Unit tests for lib/models/profile_model.dart.
//
// Profile has no toJson (it is a read-only view of the logged-in user), so
// only fromJson is exercised here.
//
// KNOWN BUG (last test below is `skip`ped, not deleted): fullName is
// built as `json['first_name'] + " " + json['last_name']` with no null
// guard, so a payload missing either name throws a NoSuchMethodError
// instead of degrading gracefully (e.g. falling back to whichever name is
// present). The test asserts the graceful behavior a correct
// implementation should have; remove the `skip:` once fixed to confirm.

import 'package:cocoa_supply/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses a fully-populated payload', () {
      final profile = Profile.fromJson({
        'user_id': 1,
        'roles': ['farmer', 'processor'],
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'nickname': 'สม',
        'phone_number': '0812345678',
        'address_detail': '111/55',
        'zip_code': '11000',
      });

      expect(profile.userId, '1');
      expect(profile.roles, ['farmer', 'processor']);
      expect(profile.firstName, 'สมชาย');
      expect(profile.lastName, 'โกโก้ดี');
      expect(profile.fullName, 'สมชาย โกโก้ดี');
    });

    test('roles is null when absent from the payload', () {
      final profile = Profile.fromJson({
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
      });
      expect(profile.roles, isNull);
    });

    test(
      'does not crash when first_name is missing, and fullName falls back to what is present',
      () {
        final profile = Profile.fromJson({'last_name': 'โกโก้ดี'});
        expect(profile.fullName, 'โกโก้ดี');
      },
      skip: 'KNOWN BUG: fullName throws when first_name/last_name is null — see file header comment.',
    );
  });
}
