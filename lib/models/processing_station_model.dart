import 'package:cocoa_supply/models/batch_model.dart';

class ProcessingStation {
  final String? processingStationId;
  final String? processingStationName;
  final String? hubId;
  final DateTime? foundDate;
  final double? processingStationArea;
  final String? addressDetail;
  final String? subdistrictId;
  final String? districtId;
  final String? provinceId;
  final String? zipCode;
  final String? contactName;
  final String? phoneNumber;
  final String? line;
  final String? facebook;
  final List<Batch>? batches; // เพิ่มลิสต์ของ Batches (ที่มี origin อยู่ข้างใน)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProcessingStation({
    this.processingStationId,
    this.processingStationName,
    this.hubId,
    this.foundDate,
    this.processingStationArea,
    this.addressDetail,
    this.subdistrictId,
    this.districtId,
    this.provinceId,
    this.zipCode,
    this.contactName,
    this.phoneNumber,
    this.line,
    this.facebook,
    this.batches,
    this.createdAt,
    this.updatedAt,
  });

  factory ProcessingStation.fromJson(Map<String, dynamic> json) => ProcessingStation(
    processingStationId: json['processing_station_id']?.toString(),
    processingStationName: json['processing_station_name'],
    hubId: json['hub_id']?.toString(),
    foundDate: json['found_date'] != null ? DateTime.tryParse(json['found_date']) : null,
    processingStationArea: json['processing_station_area'] != null ? double.tryParse(json['processing_station_area'].toString()) : null,
    addressDetail: json['address_detail'],
    subdistrictId: json['subdistrict_id']?.toString(),
    districtId: json['district_id']?.toString(),
    provinceId: json['province_id']?.toString(),
    zipCode: json['zip_code'],
    contactName: json['contact_name'],
    phoneNumber: json['phone_number'],
    line: json['line'],
    facebook: json['facebook'],
    // ทำการ Map รายการ batches จาก JSON list เข้าสู่ Class Batch
    batches: json['batches'] != null 
        ? (json['batches'] as List).map((i) => Batch.fromJson(i)).toList() 
        : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'processing_station_id': processingStationId,
    'processing_station_name': processingStationName,
    'hub_id': hubId,
    'found_date': foundDate?.toIso8601String(),
    'processing_station_area': processingStationArea,
    'address_detail': addressDetail,
    'subdistrict_id': subdistrictId,
    'district_id': districtId,
    'province_id': provinceId,
    'zip_code': zipCode,
    'contact_name': contactName,
    'phone_number': phoneNumber,
    'line': line,
    'facebook': facebook,
    'batches': batches?.map((v) => v.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}