import 'package:cocoa_supply/models/harvest_model.dart';

class Hub {
  final String? hubId;
  final String? hubName;
  final DateTime? foundDate;
  final String? addressDetail;
  final String? subdistrictId;
  final String? districtId;
  final String? provinceId;
  final String? zipCode;
  final String? contactName;
  final String? phoneNumber;
  final String? line;
  final String? facebook;
  final List<Harvest>? harvests; // เพิ่มลิสต์ของ Harvests เข้ามา
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Hub({
    this.hubId,
    this.hubName,
    this.foundDate,
    this.addressDetail,
    this.subdistrictId,
    this.districtId,
    this.provinceId,
    this.zipCode,
    this.contactName,
    this.phoneNumber,
    this.line,
    this.facebook,
    this.harvests,
    this.createdAt,
    this.updatedAt,
  });

  factory Hub.fromJson(Map<String, dynamic> json) => Hub(
    hubId: json['hub_id']?.toString(),
    hubName: json['hub_name'],
    foundDate: json['found_date'] != null ? DateTime.tryParse(json['found_date']) : null,
    addressDetail: json['address_detail'],
    subdistrictId: json['subdistrict_id']?.toString(),
    districtId: json['district_id']?.toString(),
    provinceId: json['province_id']?.toString(),
    zipCode: json['zip_code'],
    contactName: json['contact_name'],
    phoneNumber: json['phone_number'],
    line: json['line'],
    facebook: json['facebook'],
    // ทำการ Map รายการ harvests จาก JSON list เข้าสู่ Class Harvest ที่เราแก้ไว้ก่อนหน้านี้
    harvests: json['harvests'] != null 
        ? (json['harvests'] as List).map((i) => Harvest.fromJson(i)).toList() 
        : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'hub_id': hubId,
    'hub_name': hubName,
    'found_date': foundDate?.toIso8601String(),
    'address_detail': addressDetail,
    'subdistrict_id': subdistrictId,
    'district_id': districtId,
    'province_id': provinceId,
    'zip_code': zipCode,
    'contact_name': contactName,
    'phone_number': phoneNumber,
    'line': line,
    'facebook': facebook,
    'harvests': harvests?.map((v) => v.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}