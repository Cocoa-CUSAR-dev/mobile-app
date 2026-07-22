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

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: json['user_id']?.toString(),
        roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),

        firstName: json['first_name'],
        lastName: json['last_name'],
        nickname: json['nickname'],
        phoneNumber: json['phone_number'],
        line: json['line'],
        facebook: json['facebook'],
        addressDetail: json['address_detail'],
        subdistrictName: json['subdistrict_name'],
        districtName: json['district_name'],
        provinceName: json['province_name'],
        zipCode: json['zip_code'],
        fullName: json['first_name'] + " " + json['last_name'],
      );
}