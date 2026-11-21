import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/fuel_metrics.dart';

class FuelCharts extends StatelessWidget {
  final List<FuelingMetric> metrics;

  const FuelCharts({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    // filtra a partir do 2º abastecimento (onde há km/l e r$/km)
    final validPoints = metrics.where((m) => m.hasConsumptionMetrics).toList();

    if (validPoints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Registre pelo menos 2 abastecimentos (tanque completo) para visualizar os gráficos de evolução de km/L e R\$/km.',
          ),
        ),
      );
    }

    final numberFormat = NumberFormat('#,##0.00', 'pt_BR');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      children: [
        _MetricLineChartCard(
          title: 'Evolução do Consumo (km/L)',
          subtitle: 'A partir do 2º abastecimento',
          color: Colors.teal,
          points: validPoints.map((m) => FlSpot(m.index.toDouble(), m.kmPerLiter!)).toList(),
          xLabels: validPoints.map((m) => '#${m.index}').toList(),
          formatY: (val) => '${numberFormat.format(val)} km/L',
        ),
        const SizedBox(height: 12),
        _MetricLineChartCard(
          title: 'Evolução do Custo por Km (R\$/km)',
          subtitle: 'A partir do 2º abastecimento',
          color: Colors.deepOrange,
          points: validPoints.map((m) => FlSpot(m.index.toDouble(), m.costPerKm!)).toList(),
          xLabels: validPoints.map((m) => '#${m.index}').toList(),
          formatY: (val) => '${currencyFormat.format(val)}/km',
        ),
      ],
    );
  }
}

class _MetricLineChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<FlSpot> points;
  final List<String> xLabels;
  final String Function(double) formatY;

  const _MetricLineChartCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.points,
    required this.xLabels,
    required this.formatY,
  });

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final margin = ((maxY - minY).abs() * 0.2).clamp(0.2, 5.0);

    final chartMinY = (minY - margin) < 0 ? 0.0 : (minY - margin);
    final chartMaxY = maxY + margin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            formatY(spot.y),
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = points.indexWhere((p) => p.x == value);
                          if (idx == -1 || idx >= xLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              xLabels[idx],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}