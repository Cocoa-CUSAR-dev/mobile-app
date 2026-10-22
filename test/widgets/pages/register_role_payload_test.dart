// rolePayload (lib/widgets/pages/register_role_page.dart): the profile body
// sent to backend-hub's POST /api/v1/me/roles/{role}. The hub rejects any
// field that isn't a column of that role's profile table.

import 'package:cocoa_supply/widgets/pages/register_role_page.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> filledForm() => {
  'first_name': 'สมชาย',
  'last_name': 'ใจดี',
  'nickname': 'ชาย',
  'birth_date': '1980-01-02',
  'id_card_number': '',
  'address_detail': '',
  'zip_code': '',
  'phone_number': '0812345678',
  'line': '',
  'email': 'a@b.c',
  'salary_income': '1200.50',
  'family_member_count': '4',
  'agri_worker_count': '0',
  'agri_experience': '',
  'province_id': 'p-1',
  'district_id': 'd-1',
  'subdistrict_id': 's-1',
};

void main() {
  test(
    'farmer: its own fields, numbers as numbers, blanks and email left out',
    () {
      expect(rolePayload('farmer', filledForm()), {
        'first_name': 'สมชาย',
        'last_name': 'ใจดี',
        'nickname': 'ชาย',
        'phone_number': '0812345678',
        'province_id': 'p-1',
        'district_id': 'd-1',
        'subdistrict_id': 's-1',
        'birth_date': '1980-01-02',
        'salary_income': 1200.5,
        'family_member_count': 4,
        'agri_worker_count': 0,
      });
    },
  );

  test(
    'farmer: a household of 0 is "not filled in", so the DB default stays',
    () {
      final payload = rolePayload('farmer', {
        ...filledForm(),
        'family_member_count': '0',
      });
      expect(payload.containsKey('family_member_count'), isFalse);
    },
  );

  test('processor gets no farmer-only fields', () {
    final payload = rolePayload('processor', filledForm());
    expect(payload.keys, isNot(contains('salary_income')));
    expect(payload.keys, isNot(contains('family_member_count')));
    expect(payload.keys, isNot(contains('email')));
    expect(payload['birth_date'], '1980-01-02');
  });

  test("hub collector's date of birth goes in its 'birthdate' column", () {
    final payload = rolePayload('hub_collector', filledForm());
    expect(payload['birthdate'], '1980-01-02');
    expect(payload.containsKey('birth_date'), isFalse);
    expect(payload.containsKey('address_detail'), isFalse);
  });
}
