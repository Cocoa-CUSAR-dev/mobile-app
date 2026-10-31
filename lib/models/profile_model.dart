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
  /// The profile's subdistrict id, to look its place names up by.
  final String? subdistrictId;
  final String? fullName;
  final List<String>? roles; // ← เพิ่มเพราะ roles อยู่ระดับเดียวกันแล้ว
  final String? userId;      // ← เผื่อใช้ user_id
  /// Each role's own profile from GET /me (`profiles.farmer`, ...); a role
  /// the person doesn't hold has none.
  final Map<String, dynamic> profiles;

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
    this.subdistrictId,
    this.fullName,
    this.roles,
    this.userId,
    this.profiles = const {},
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
      profiles: {
        for (final entry in ((json['profiles'] as Map?) ?? const {}).entries)
          if (entry.value is Map) '${entry.key}': entry.value,
      },
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),
      firstName: first,
      lastName: last,
      nickname: source['nickname'],
      phoneNumber: source['phone_number'],
      line: source['line'],
      facebook: source['facebook'],
      addressDetail: source['address_detail'],
      // The profile holds the ids of the subdistrict, district and province,
      // not their names: AuthService fills these in with [withPlaceNames].
      subdistrictName: source['subdistrict_name'],
      districtName: source['district_name'],
      provinceName: source['province_name'],
      zipCode: source['zip_code'],
      subdistrictId: source['subdistrict_id']?.toString(),
      fullName: name.isEmpty ? null : name,
    );
  }

  /// This profile with its subdistrict, district and province names, e.g.
  /// from one row of GET /api/v1/ref/constants/location.
  Profile withPlaceNames({
    String? subdistrictName,
    String? districtName,
    String? provinceName,
  }) =>
      Profile(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        phoneNumber: phoneNumber,
        line: line,
        facebook: facebook,
        addressDetail: addressDetail,
        subdistrictName: subdistrictName ?? this.subdistrictName,
        districtName: districtName ?? this.districtName,
        provinceName: provinceName ?? this.provinceName,
        zipCode: zipCode,
        subdistrictId: subdistrictId,
        fullName: fullName,
        roles: roles,
        userId: userId,
        profiles: profiles,
      );

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