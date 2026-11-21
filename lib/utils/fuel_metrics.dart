import '../models/fueling.dart';

class FuelingMetric {
  final int index; // 1 para o 1º abastecimento, 2 para o 2º, etc.
  final Fueling fueling;
  final double? distanceKm;
  final double? kmPerLiter;
  final double? costPerKm;

  const FuelingMetric({
    required this.index,
    required this.fueling,
    this.distanceKm,
    this.kmPerLiter,
    this.costPerKm,
  });

  bool get hasConsumptionMetrics => kmPerLiter != null && costPerKm != null;
}

class FuelMetrics {
  // calcula métricas ordenando por quilometragem e data
  static List<FuelingMetric> calculateAll(List<Fueling> fuelings) {
    final sorted = List<Fueling>.from(fuelings)
      ..sort((a, b) {
        final kmCmp = a.odometerKm.compareTo(b.odometerKm);
        if (kmCmp != 0) return kmCmp;
        return a.dateTime.compareTo(b.dateTime);
      });

    final List<FuelingMetric> results = [];

    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];

      // 1º abastecimento serve apenas como referência inicial
      if (i == 0) {
        results.add(
          FuelingMetric(
            index: 1,
            fueling: current,
          ),
        );
        continue;
      }

      final previous = sorted[i - 1];
      final distance = current.odometerKm - previous.odometerKm;

      double? kmPerLiter;
      double? costPerKm;

      if (distance > 0 && current.liters > 0) {
        kmPerLiter = distance / current.liters;
        costPerKm = current.totalValue / distance;
      }

      results.add(
        FuelingMetric(
          index: i + 1,
          fueling: current,
          distanceKm: distance > 0 ? distance : null,
          kmPerLiter: kmPerLiter,
          costPerKm: costPerKm,
        ),
      );
    }

    return results;
  }

  // retorna apenas os abastecimentos que já possuem indicadores de km/l e r$/km
  static List<FuelingMetric> measurableMetrics(List<Fueling> fuelings) {
    return calculateAll(fuelings)
        .where((m) => m.hasConsumptionMetrics)
        .toList();
  }
}