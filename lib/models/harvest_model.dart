class Harvest {
  final String? harvestId;
  final String? hubId;
  final String? farmId;
  final String? farmName; // เพิ่มจาก Join
  final String? name;     // สำหรับ Dropdown: ฟาร์มเฮาส์ (01 พ.ค. 2569)
  final String? plotId;
  final String? gradeCode; // จาก harvest_grade_detail
  final double? quantityKg; // จาก harvest_grade_detail
  final String? gradeDescription;
  final bool? isClean;
  final double? weightGramPerPod;
  final String? batchId;      // จาก harvest_collection
  final String? collectionId; // จาก harvest_collection
  final String? logisticResult;
  final DateTime? harvestDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Harvest({
    this.harvestId,
    this.hubId,
    this.farmId,
    this.farmName,
    this.name,
    this.plotId,
    this.gradeCode,
    this.quantityKg,
    this.gradeDescription,
    this.isClean,
    this.weightGramPerPod,
    this.batchId,
    this.collectionId,
    this.logisticResult,
    this.harvestDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Harvest.fromJson(Map<String, dynamic> json) => Harvest(
    harvestId: json['harvest_id']?.toString(),
    hubId: json['hub_id']?.toString(),
    farmId: json['farm_id']?.toString(),
    farmName: json['farm_name'],
    name: json['name'],
    plotId: json['plot_id']?.toString(),
    gradeCode: json['grade_code'],
    quantityKg: json['quantity_kg'] != null ? double.tryParse(json['quantity_kg'].toString()) : null,
    gradeDescription: json['grade_description'],
    isClean: json['is_clean'],
    weightGramPerPod: json['weight_gram_per_pod'] != null ? double.tryParse(json['weight_gram_per_pod'].toString()) : null,
    batchId: json['batch_id']?.toString(),
    collectionId: json['collection_id']?.toString(),
    logisticResult: json['logistic_result'],
    harvestDate: json['harvest_date'] != null ? DateTime.tryParse(json['harvest_date']) : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'harvest_id': harvestId,
    'hub_id': hubId,
    'farm_id': farmId,
    'farm_name': farmName,
    'name': name,
    'plot_id': plotId,
    'grade_code': gradeCode,
    'quantity_kg': quantityKg,
    'batch_id': batchId,
    'collection_id': collectionId,
    'logistic_result': logisticResult,
    'harvest_date': harvestDate?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}