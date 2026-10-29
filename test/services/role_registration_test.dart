import 'package:cocoa_supply/services/role_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('registrationSteps', () {
    List<String> fields(Set<String> roles) => registrationSteps(roles).expand((s) => s).toList();

    test('asks each shared field once, however many roles are picked', () {
      final all = fields({'farmer', 'hub_collector', 'processor'});
      expect(all.toSet().length, all.length);
      expect(all, containsAll(['first_name', 'phone_number', 'province_id', 'zip_code']));
    });

    test('farmer adds its own pages; hub and processor do not', () {
      expect(fields({'farmer'}), containsAll(['salary_income', 'agri_experience']));
      expect(fields({'hub_collector', 'processor'}), isNot(contains('salary_income')));
    });

    test('ID card only for hub or processor, address only for farmer or processor', () {
      expect(fields({'farmer'}), isNot(contains('id_card_number')));
      expect(fields({'hub_collector'}), contains('id_card_number'));
      expect(fields({'hub_collector'}), isNot(contains('address_detail')));
      expect(fields({'farmer'}), contains('address_detail'));
    });

    test('no page has more than three fields', () {
      for (final step in registrationSteps({'farmer', 'hub_collector', 'processor'})) {
        expect(step.length, lessThanOrEqualTo(3));
      }
    });
  });

  group('isRegistrationFieldRequired', () {
    test('a field is required when any picked role needs it', () {
      expect(isRegistrationFieldRequired('id_card_number', {'farmer'}), isFalse);
      expect(isRegistrationFieldRequired('id_card_number', {'farmer', 'processor'}), isTrue);
      expect(isRegistrationFieldRequired('zip_code', {'hub_collector'}), isFalse);
      expect(isRegistrationFieldRequired('zip_code', {'hub_collector', 'farmer'}), isTrue);
      expect(isRegistrationFieldRequired('first_name', {'hub_collector'}), isTrue);
    });
  });

  group('registrationPrefill', () {
    test('takes the shared fields of the first profile the person has', () {
      final prefill = registrationPrefill({
        'farmer': null,
        'hub_collector': {
          'first_name': 'สมชาย',
          'birthdate': '1990-01-02',
          'province_id': 'p-1',
          'phone_number': null,
          'hub_collector_id': 'not-a-form-field',
        },
      });
      expect(prefill, {'first_name': 'สมชาย', 'birth_date': '1990-01-02', 'province_id': 'p-1'});
    });

    test('nothing to start with when the person has no profile', () {
      expect(registrationPrefill({'farmer': null}), isEmpty);
      expect(registrationPrefill({}), isEmpty);
    });
  });
}
