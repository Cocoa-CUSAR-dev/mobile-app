import 'package:cocoa_supply/models/plot_model.dart';

class Farm {
  final String? farmId;
  final String? farmName;
  final String? hubId;
  final DateTime? foundDate;
  final double? totalArea;
  final String? addressDetail;
  final String? subdistrictId;
  final String? districtId;
  final String? provinceId;
  final String? zipCode;
  final String? contactName;
  final String? phoneNumber;
  final String? line;
  final String? facebook;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  List<Plot>? plots; // คงไว้ตามโครงสร้างเดิม

  Farm({
    this.farmId,
    this.farmName,
    this.hubId,
    this.foundDate,
    this.totalArea,
    this.addressDetail,
    this.subdistrictId,
    this.districtId,
    this.provinceId,
    this.zipCode,
    this.contactName,
    this.phoneNumber,
    this.line,
    this.facebook,
    this.createdAt,
    this.updatedAt,
    this.plots,
  });

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
    farmId: json['farm_id']?.toString(),
    farmName: json['farm_name'],
    hubId: json['hub_id']?.toString(),
    foundDate: json['found_date'] != null ? DateTime.tryParse(json['found_date']) : null,
    totalArea: json['total_area'] != null ? double.tryParse(json['total_area'].toString()) : null,
    addressDetail: json['address_detail'],
    subdistrictId: json['subdistrict_id']?.toString(),
    districtId: json['district_id']?.toString(),
    provinceId: json['province_id']?.toString(),
    zipCode: json['zip_code'],
    contactName: json['contact_name'],
    phoneNumber: json['phone_number'],
    line: json['line'],
    facebook: json['facebook'],
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    // ✅ แก้ไขตรงนี้: ดึงข้อมูล plots มาแปลงเป็น List<Plot>
    plots: json['plots'] != null 
        ? (json['plots'] as List).map((i) => Plot.fromJson(i)).toList() 
        : null,
  );

  Map<String, dynamic> toJson() => {
    'farm_id': farmId,
    'farm_name': farmName,
    'hub_id': hubId,
    'found_date': foundDate?.toIso8601String(),
    'total_area': totalArea,
    'address_detail': addressDetail,
    'subdistrict_id': subdistrictId,
    'district_id': districtId,
    'province_id': provinceId,
    'zip_code': zipCode,
    'contact_name': contactName,
    'phone_number': phoneNumber,
    'line': line,
    'facebook': facebook,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    // ✅ เพิ่มการส่งค่า plots กลับเป็น JSON ถ้าต้องการ
    if (plots != null) 'plots': plots!.map((v) => v.toJson()).toList(),
  };
}