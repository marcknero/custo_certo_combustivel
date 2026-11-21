enum FuelType {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  final String label;
  const FuelType(this.label);

  static FuelType fromName(String? value) {
    return FuelType.values.firstWhere(
      (type) => type.name == value || type.label.toLowerCase() == value?.toLowerCase(),
      orElse: () => FuelType.gasolina,
    );
  }
}

class Fueling {
  final String id;
  final FuelType fuelType;
  final double pricePerLiter;
  final double odometerKm;
  final double liters;
  final DateTime dateTime;

  const Fueling({
    required this.id,
    required this.fuelType,
    required this.pricePerLiter,
    required this.odometerKm,
    required this.liters,
    required this.dateTime,
  });

  // valor total do abastecimento = preço por litro * litros abastecidos
  double get totalValue => pricePerLiter * liters;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fuelType': fuelType.name,
      'pricePerLiter': pricePerLiter,
      'odometerKm': odometerKm,
      'liters': liters,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Fueling.fromJson(Map<String, dynamic> json) {
    return Fueling(
      id: json['id']?.toString() ?? '',
      fuelType: FuelType.fromName(json['fuelType']?.toString()),
      pricePerLiter: (json['pricePerLiter'] as num?)?.toDouble() ?? 0.0,
      odometerKm: (json['odometerKm'] as num?)?.toDouble() ?? 0.0,
      liters: (json['liters'] as num?)?.toDouble() ?? 0.0,
      dateTime: DateTime.tryParse(json['dateTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}