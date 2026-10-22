// Unit tests for lib/models/profile_model.dart.
//
// Profile has no toJson (it is a read-only view of the logged-in user), so
// only fromJson is exercised here.

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
    );

    test('reads the shape of GET /api/v1/me: roles at the top, one profile per role', () {
      final profile = Profile.fromJson({
        'user_id': 'u-1',
        'username': '0812345678',
        'roles': ['hub_collector', 'farmer'],
        'must_reset_password': false,
        'profiles': {
          'farmer': {'first_name': 'สมชาย', 'last_name': 'ใจดี', 'phone_number': '0812345678'},
          'hub_collector': {'first_name': 'ไม่ใช่ชื่อนี้', 'last_name': 'x'},
          'processor': null,
          'researcher': null,
        },
      });

      expect(profile.userId, 'u-1');
      expect(profile.roles, ['hub_collector', 'farmer']);
      expect(profile.fullName, 'สมชาย ใจดี');
      expect(profile.phoneNumber, '0812345678');
    });

    test('falls back to the next role when the first has no profile', () {
      final profile = Profile.fromJson({
        'user_id': 'u-1',
        'roles': ['processor'],
        'profiles': {
          'farmer': null,
          'hub_collector': null,
          'processor': {'first_name': 'มาลี', 'last_name': 'แปรรูป'},
          'researcher': null,
        },
      });

      expect(profile.fullName, 'มาลี แปรรูป');
    });

    test('an account with no profile yet has no name, and does not crash', () {
      final profile = Profile.fromJson({
        'user_id': 'u-1',
        'roles': <String>[],
        'profiles': {'farmer': null, 'hub_collector': null, 'processor': null, 'researcher': null},
      });

      expect(profile.fullName, isNull);
      expect(profile.firstName, isNull);
      expect(profile.roles, isEmpty);
    });
  });
}
