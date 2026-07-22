class Batch {
  final String? batchId;
  final String? processingStationId;
  final String? processingStationName; // เพิ่มสำหรับ UI
  final String? origin;
  final String? name; // สำหรับ Dropdown: ริมรั้ว (30 เม.ย. 2569)
  final String? notes;
  final double? quantityKg;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Batch({
    this.batchId,
    this.processingStationId,
    this.processingStationName,
    this.origin,
    this.name,
    this.notes,
    this.quantityKg,
    this.createdAt,
    this.updatedAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    batchId: json['batch_id']?.toString(),
    processingStationId: json['processing_station_id']?.toString(),
    processingStationName: json['processing_station_name'],
    origin: json['origin'],
    name: json['name'], // รับค่าจากที่ SQL ต่อ String มาให้
    notes: json['notes'],
    quantityKg: json['quantity_kg'] != null ? double.tryParse(json['quantity_kg'].toString()) : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'processing_station_id': processingStationId,
    'processing_station_name': processingStationName,
    'origin': origin,
    'name': name,
    'notes': notes,
    'quantity_kg': quantityKg,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}