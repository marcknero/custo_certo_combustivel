class Vehicle {
  final String brandCode;
  final String brandName;
  final String modelCode;
  final String modelName;
  final int year;
  final String engineDisplacement;

  const Vehicle({
    required this.brandCode,
    required this.brandName,
    required this.modelCode,
    required this.modelName,
    required this.year,
    required this.engineDisplacement,
  });

  // converte o objeto para mapa json na persistência local
  Map<String, dynamic> toJson() {
    return {
      'brandCode': brandCode,
      'brandName': brandName,
      'modelCode': modelCode,
      'modelName': modelName,
      'year': year,
      'engineDisplacement': engineDisplacement,
    };
  }

  // reconstrói o veículo a partir do json salvo
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      brandCode: json['brandCode']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      modelCode: json['modelCode']?.toString() ?? '',
      modelName: json['modelName']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '') ?? 0,
      engineDisplacement: json['engineDisplacement']?.toString() ?? '',
    );
  }
}