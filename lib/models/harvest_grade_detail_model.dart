class HarvestGradeDetail {
  final String? harvestId;
  final String? gradeCode;
  final double? quantityKg;
  final String? description;
  final bool? isClean;
  final bool? isAppropriateSize;
  final double? weightGramPerPod;
  final bool? isSprout;
  final bool? isDry;
  final bool? isShriveled;
  final String? cutTestResult;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HarvestGradeDetail({
    this.harvestId,
    this.gradeCode,
    this.quantityKg,
    this.description,
    this.isClean,
    this.isAppropriateSize,
    this.weightGramPerPod,
    this.isSprout,
    this.isDry,
    this.isShriveled,
    this.cutTestResult,
    this.createdAt,
    this.updatedAt,
  });

  factory HarvestGradeDetail.fromJson(Map<String, dynamic> json) => HarvestGradeDetail(
    harvestId: json['harvest_id']?.toString(),
    gradeCode: json['grade_code'],
    quantityKg: json['quantity_kg'] != null ? double.tryParse(json['quantity_kg'].toString()) : null,
    description: json['description'],
    isClean: json['is_clean'],
    isAppropriateSize: json['is_appropriate_size'],
    weightGramPerPod: json['weight_gram_per_pod'] != null ? double.tryParse(json['weight_gram_per_pod'].toString()) : null,
    isSprout: json['is_sprout'],
    isDry: json['is_dry'],
    isShriveled: json['is_shriveled'],
    cutTestResult: json['cut_test_result'],
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'harvest_id': harvestId,
    'grade_code': gradeCode,
    'quantity_kg': quantityKg,
    'description': description,
    'is_clean': isClean,
    'is_appropriate_size': isAppropriateSize,
    'weight_gram_per_pod': weightGramPerPod,
    'is_sprout': isSprout,
    'is_dry': isDry,
    'is_shriveled': isShriveled,
    'cut_test_result': cutTestResult,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}