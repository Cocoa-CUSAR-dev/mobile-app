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

    test('about you, then address, then the role page only when a role has one', () {
      final steps = registrationSteps({'farmer'});
      expect(steps, hasLength(3));
      expect(steps[0], containsAll(['first_name', 'birth_date', 'phone_number', 'line']));
      expect(steps[1], containsAll(['province_id', 'subdistrict_id', 'zip_code']));
      expect(steps[2], farmerOwnFields);
      expect(registrationSteps({'hub_collector'})[2], ['id_card_number']);
    });

    test('the ID card is asked once even when the hub collector and processor are both picked', () {
      final roleStep = registrationSteps({'hub_collector', 'processor', 'farmer'})[2];
      expect(roleStep.where((f) => f == 'id_card_number'), hasLength(1));
    });
  });

  group('rolesAsking', () {
    test('names the picked roles a role-only field is for', () {
      expect(rolesAsking('id_card_number', {'hub_collector', 'processor', 'farmer'}), ['hub_collector', 'processor']);
      expect(rolesAsking('id_card_number', {'processor'}), ['processor']);
      expect(rolesAsking('salary_income', {'farmer', 'processor'}), ['farmer']);
      expect(rolesAsking('first_name', {'farmer'}), isEmpty);
    });
  });

  group('signUpPrefill', () {
    test('the phone number signed up with fills the profile phone', () {
      expect(signUpPrefill('0812345678'), {'phone_number': '0812345678'});
      expect(signUpPrefill(' 0812345678 '), {'phone_number': '0812345678'});
    });

    test('nothing for an email or a blank username', () {
      expect(signUpPrefill('somchai@example.com'), isEmpty);
      expect(signUpPrefill(''), isEmpty);
      expect(signUpPrefill(null), isEmpty);
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

  group('sharedAnswers', () {
    test('keeps name, phone and address; drops fields only one role has', () {
      final shared = sharedAnswers({
        'first_name': 'สมชาย',
        'phone_number': '0812345678',
        'province_id': 'p-1',
        'salary_income': 15000.0,
        'agri_worker_count': 2,
      });
      expect(shared, {'first_name': 'สมชาย', 'phone_number': '0812345678', 'province_id': 'p-1'});
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

  group('clearedFields', () {
    const prefill = {'line': 'somchai', 'zip_code': '10110', 'first_name': 'สมชาย'};

    test('an optional field emptied since the form opened', () {
      final form = {'line': ' ', 'zip_code': '10110', 'first_name': 'สมชาย'};
      expect(clearedFields(prefill, form, 'processor'), {'line'});
    });

    test('not a field the role requires', () {
      final form = {'line': 'somchai', 'zip_code': '', 'first_name': ''};
      expect(clearedFields(prefill, form, 'farmer'), isEmpty);
      expect(clearedFields(prefill, form, 'processor'), {'zip_code'});
    });

    test('not a field that was blank already, or that the form lacks', () {
      expect(clearedFields(const {'line': ''}, {'line': ''}, 'farmer'), isEmpty);
      expect(clearedFields(const {'line': 'somchai'}, {}, 'farmer'), isEmpty);
    });
  });
}
