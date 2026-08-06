// Unit tests for lib/models/profile_model.dart.
//
// Profile has no toJson (it is a read-only view of the logged-in user), so
// only fromJson is exercised here.
//
// Known limitation documented by the second test: fullName is built as
// `json['first_name'] + " " + json['last_name']` with no null guard, so a
// payload missing either name throws instead of degrading gracefully. This
// test pins that current behavior rather than silently masking it.

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

    test('throws when first_name or last_name is missing (documented current behavior)', () {
      expect(
        () => Profile.fromJson({'last_name': 'โกโก้ดี'}),
        throwsA(anything),
      );
    });
  });
}
