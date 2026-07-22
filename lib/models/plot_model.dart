class Plot {
  final String? plotId;
  final String? farmId;
  final String? plotName;
  final double? totalArea;
  final String? landOwnership;
  final double? cocoaPlantedArea;
  final bool? hasChemicalUse;
  final String? landTypeId;
  final String? soilTypeId;
  final String? waterSourceId;
  final String? wateringSystemId;
  final DateTime? foundDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plot({
    this.plotId,
    this.farmId,
    this.plotName,
    this.totalArea,
    this.landOwnership,
    this.cocoaPlantedArea,
    this.hasChemicalUse,
    this.landTypeId,
    this.soilTypeId,
    this.waterSourceId,
    this.wateringSystemId,
    this.foundDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Plot.fromJson(Map<String, dynamic> json) => Plot(
    plotId: json['plot_id']?.toString(),
    farmId: json['farm_id']?.toString(),
    plotName: json['plot_name'],
    totalArea: json['total_area'] != null ? double.tryParse(json['total_area'].toString()) : null,
    landOwnership: json['land_ownership'],
    cocoaPlantedArea: json['cocoa_planted_area'] != null ? double.tryParse(json['cocoa_planted_area'].toString()) : null,
    hasChemicalUse: json['has_chemical_use'],
    landTypeId: json['land_type_id']?.toString(),
    soilTypeId: json['soil_type_id']?.toString(),
    waterSourceId: json['water_source_id']?.toString(),
    wateringSystemId: json['watering_system_id']?.toString(),
    foundDate: json['found_date'] != null ? DateTime.tryParse(json['found_date']) : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'plot_id': plotId,
    'farm_id': farmId,
    'plot_name': plotName,
    'total_area': totalArea,
    'land_ownership': landOwnership,
    'cocoa_planted_area': cocoaPlantedArea,
    'has_chemical_use': hasChemicalUse,
    'land_type_id': landTypeId,
    'soil_type_id': soilTypeId,
    'water_source_id': waterSourceId,
    'watering_system_id': wateringSystemId,
    'found_date': foundDate?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}