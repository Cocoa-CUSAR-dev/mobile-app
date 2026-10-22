// What POST /api/v1/me/roles/{role} accepts for each role: the fields of that
// role's profile and nothing else. The registration form is one page for all
// three roles, so it collects more than any one of them takes (an email, a
// birth date for a role whose column is spelled differently), and the backend
// refuses a field it does not know.

const Set<String> _contact = {
  'first_name',
  'last_name',
  'nickname',
  'id_card_number',
  'phone_number',
  'line',
  'facebook',
  'subdistrict_id',
  'district_id',
  'province_id',
  'zip_code',
};

const Map<String, Set<String>> _fieldsByRole = {
  'farmer': {
    ..._contact,
    'birth_date',
    'nationality',
    'ethnicity',
    'religion',
    'address_detail',
    'salary_income',
    'family_member_count',
    'agri_worker_count',
    'agri_experience',
  },
  'processor': {..._contact, 'birth_date', 'address_detail'},
  // This role's birth date column is spelled "birthdate".
  'hub_collector': {..._contact, 'birthdate'},
};

/// The body for adding [role] from the registration [form]'s answers.
Map<String, dynamic> roleProfilePayload(
  String role,
  Map<String, dynamic> form,
) {
  final allowed = _fieldsByRole[role];
  if (allowed == null) {
    throw ArgumentError.value(role, 'role', 'not a role the app can register');
  }
  final answers = {
    for (final entry in form.entries)
      (role == 'hub_collector' && entry.key == 'birth_date')
              ? 'birthdate'
              : entry.key:
          entry.value,
  };
  return {
    for (final entry in answers.entries)
      if (allowed.contains(entry.key) && !_isBlank(entry.value))
        entry.key: entry.value,
  };
}

bool _isBlank(Object? value) =>
    value == null || (value is String && value.trim().isEmpty);
