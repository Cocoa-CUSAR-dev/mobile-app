import 'package:cocoa_supply/services/role_profile_payload.dart';
import 'package:flutter_test/flutter_test.dart';

// What the registration form collects for every role, filled in.
Map<String, dynamic> form() => {
  'first_name': 'สมชาย',
  'last_name': 'ใจดี',
  'nickname': '',
  'birth_date': '1990-05-01',
  'id_card_number': '1234567890123',
  'address_detail': '12 หมู่ 3',
  'zip_code': '50000',
  'phone_number': '0812345678',
  'line': '',
  'email': 'x@example.com',
  'salary_income': 12000.5,
  'family_member_count': 4,
  'agri_worker_count': 2,
  'agri_experience': '',
  'province_id': 'p1',
  'district_id': 'd1',
  'subdistrict_id': 's1',
};

void main() {
  group('roleProfilePayload', () {
    test('a farmer keeps the farmer fields and loses the email', () {
      final body = roleProfilePayload('farmer', form());

      expect(
        body.keys,
        containsAll(['first_name', 'last_name', 'birth_date', 'salary_income']),
      );
      expect(body.containsKey('email'), isFalse);
      expect(body['salary_income'], 12000.5);
      expect(body['family_member_count'], 4);
    });

    test('blank answers are left out, not sent as empty strings', () {
      final body = roleProfilePayload('farmer', form());

      expect(body.containsKey('nickname'), isFalse);
      expect(body.containsKey('line'), isFalse);
      expect(body.containsKey('agri_experience'), isFalse);
    });

    test('a processor loses the farmer-only fields', () {
      final body = roleProfilePayload('processor', form());

      expect(body['birth_date'], '1990-05-01');
      expect(body['address_detail'], '12 หมู่ 3');
      for (final farmerOnly in [
        'salary_income',
        'family_member_count',
        'agri_worker_count',
      ]) {
        expect(body.containsKey(farmerOnly), isFalse, reason: farmerOnly);
      }
    });

    test(
      'a hub collector sends its birth date as "birthdate" and has no address detail',
      () {
        final body = roleProfilePayload('hub_collector', form());

        expect(body['birthdate'], '1990-05-01');
        expect(body.containsKey('birth_date'), isFalse);
        expect(body.containsKey('address_detail'), isFalse);
        expect(body['id_card_number'], '1234567890123');
      },
    );

    test('keeps the place ids the pickers chose', () {
      final body = roleProfilePayload('farmer', form());

      expect(body['province_id'], 'p1');
      expect(body['district_id'], 'd1');
      expect(body['subdistrict_id'], 's1');
    });

    test('refuses a role the app cannot register', () {
      expect(
        () => roleProfilePayload('researcher', form()),
        throwsArgumentError,
      );
    });
  });
}
