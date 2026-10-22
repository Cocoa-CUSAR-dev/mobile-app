class Profile {
  final String? firstName;
  final String? lastName;
  final String? nickname;
  final String? phoneNumber;
  final String? line;
  final String? facebook;
  final String? addressDetail;
  final String? subdistrictName;
  final String? districtName;
  final String? provinceName;
  final String? zipCode;
  final String? fullName;
  final List<String>? roles; // ← เพิ่มเพราะ roles อยู่ระดับเดียวกันแล้ว
  final String? userId;      // ← เผื่อใช้ user_id

  Profile({
    this.firstName,
    this.lastName,
    this.nickname,
    this.phoneNumber,
    this.line,
    this.facebook,
    this.addressDetail,
    this.subdistrictName,
    this.districtName,
    this.provinceName,
    this.zipCode,
    this.fullName,
    this.roles,
    this.userId,
  });

  /// From GET /api/v1/me: the account, its roles and one profile per role
  /// (`profiles.farmer`, ...). The page shows one person, so the first role
  /// that has a profile supplies the name and contact details. A flat map with
  /// the profile fields at the top is still read as it always was.
  factory Profile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> source = _firstRoleProfile(json) ?? json;
    final String? first = source['first_name'];
    final String? last = source['last_name'];
    final String name = [first, last].whereType<String>().join(' ');

    return Profile(
      userId: json['user_id']?.toString(),
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),
      firstName: first,
      lastName: last,
      nickname: source['nickname'],
      phoneNumber: source['phone_number'],
      line: source['line'],
      facebook: source['facebook'],
      addressDetail: source['address_detail'],
      // The profile holds the ids of the subdistrict, district and province,
      // not their names, so these stay empty until the backend sends names.
      subdistrictName: source['subdistrict_name'],
      districtName: source['district_name'],
      provinceName: source['province_name'],
      zipCode: source['zip_code'],
      fullName: name.isEmpty ? null : name,
    );
  }

  static Map<String, dynamic>? _firstRoleProfile(Map<String, dynamic> json) {
    final Object? profiles = json['profiles'];
    if (profiles is! Map) return null;
    for (final role in const ['farmer', 'hub_collector', 'processor', 'researcher']) {
      final Object? profile = profiles[role];
      if (profile is Map<String, dynamic>) return profile;
    }
    return null;
  }
}