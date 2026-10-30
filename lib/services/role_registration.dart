// What the role registration form asks, for any set of roles picked at once.
//
// The three roles' profiles share almost every field (name, phone, address),
// so the form asks the shared ones once and adds a role's own fields only
// when that role is picked: today only the farmer has any. Each role's body
// is then cut down to its own fields by roleProfilePayload.

import 'package:cocoa_supply/config/roles.dart';

/// The pages of the form for [roles], at most three fields each.
List<List<String>> registrationSteps(Set<String> roles) {
  final farmer = roles.contains('farmer');
  final hub = roles.contains('hub_collector');
  final processor = roles.contains('processor');
  return [
    ['first_name', 'last_name', 'nickname'],
    ['birth_date', 'phone_number', 'line'],
    ['province_id', 'district_id', 'subdistrict_id'],
    [
      'zip_code',
      if (farmer || processor) 'address_detail',
      if (hub || processor) 'id_card_number',
    ],
    if (farmer) ['salary_income', 'family_member_count'],
    if (farmer) ['agri_worker_count', 'agri_experience'],
  ];
}

const Set<String> _requiredForAll = {
  'first_name',
  'last_name',
  'nickname',
  'birth_date',
  'phone_number',
  'province_id',
  'district_id',
  'subdistrict_id',
};

const Map<String, Set<String>> _requiredByRole = {
  'farmer': {'zip_code', 'salary_income', 'family_member_count', 'agri_worker_count'},
  'processor': {'id_card_number', 'address_detail'},
  'hub_collector': {'id_card_number'},
};

/// Whether [field] must be filled: it is required when any picked role needs it.
bool isRegistrationFieldRequired(String field, Set<String> roles) =>
    _requiredForAll.contains(field) ||
    roles.any((role) => _requiredByRole[role]?.contains(field) ?? false);

/// Answers to start the form with when adding a role later: the shared
/// fields of the first profile the person already has, so they don't type
/// their name and address again. [profiles] is GET /me's `profiles`.
Map<String, String> registrationPrefill(Map<String, dynamic> profiles) {
  final asked = registrationSteps(selfServiceRoles.toSet()).expand((s) => s).toSet();
  for (final role in selfServiceRoles) {
    final profile = profiles[role];
    if (profile is! Map) continue;
    final answers = <String, String>{};
    for (final entry in profile.entries) {
      // hub_collector spells its birth date column "birthdate".
      final field = entry.key == 'birthdate' ? 'birth_date' : '${entry.key}';
      if (entry.value != null && asked.contains(field)) {
        answers[field] = '${entry.value}';
      }
    }
    return answers;
  }
  return {};
}

/// Fields about the person rather than one role's work (name, phone,
/// address). Editing them in one role's profile can be applied to the
/// person's other roles too; each role still takes only the ones it has.
const Set<String> sharedProfileFields = {
  'first_name',
  'last_name',
  'nickname',
  'birth_date',
  'phone_number',
  'line',
  'facebook',
  'id_card_number',
  'province_id',
  'district_id',
  'subdistrict_id',
  'zip_code',
  'address_detail',
};

/// The shared fields of [form] only (see [sharedProfileFields]).
Map<String, dynamic> sharedAnswers(Map<String, dynamic> form) => {
      for (final entry in form.entries)
        if (sharedProfileFields.contains(entry.key)) entry.key: entry.value,
    };
