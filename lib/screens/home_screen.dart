import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fueling.dart';
import '../models/vehicle.dart';
import '../services/local_storage_service.dart';
import '../utils/fuel_metrics.dart';
import '../widgets/fuel_charts.dart';
import 'fueling_form_screen.dart';
import 'vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Vehicle? _vehicle;
  List<Fueling> _fuelings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final vehicle = await widget.storageService.getVehicle();
    final fuelings =
        vehicle != null ? await widget.storageService.getFuelings() : <Fueling>[];
    if (!mounted) return;
    setState(() {
      _vehicle = vehicle;
      _fuelings = fuelings;
      _loading = false;
    });
  }

  String _formatNum(dynamic value) {
    final numFmt = NumberFormat('#,##0.00', 'pt_BR');
    if (value is num) {
      return numFmt.format(value);
    }
    return '0,00';
  }

  String _formatMoney(dynamic value) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    if (value is num) {
      return currencyFmt.format(value);
    }
    return currencyFmt.format(0);
  }

  String _formatDate(dynamic value) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    if (value is DateTime) {
      return dateFmt.format(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return dateFmt.format(parsed);
    }
    return '—';
  }

  Future<void> _openVehicleScreen() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VehicleScreen(
          existingVehicle: _vehicle,
          storageService: widget.storageService,
        ),
      ),
    );
    if (updated == true) {
      await _loadData();
    }
  }

  Future<void> _openFuelingForm() async {
    if (_vehicle == null) return;
    final lastOdo = _fuelings.isNotEmpty ? _fuelings.last.odometerKm : null;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FuelingFormScreen(
          storageService: widget.storageService,
          lastOdometerKm: lastOdo,
        ),
      ),
    );
    if (added == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = FuelMetrics.calculateAll(_fuelings);
    final measurable = metrics.where((m) => m.hasConsumptionMetrics).toList();
    final latestMeasurable = measurable.isNotEmpty ? measurable.last : null;
    final latestFueling = metrics.isNotEmpty ? metrics.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custo Certo Combustível'),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Usar tema azul claro' : 'Ativar modo noturno',
            onPressed: () => widget.onToggleTheme(!widget.isDarkMode),
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Gerenciar veículo',
            onPressed: _openVehicleScreen,
            icon: const Icon(Icons.directions_car),
          ),
        ],
      ),
      floatingActionButton: _vehicle != null
          ? FloatingActionButton.extended(
              onPressed: _openFuelingForm,
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Abastecer'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicle == null
              ? _buildNoVehicleState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    children: [
                      _buildVehicleHeader(_vehicle!),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              title: 'Último abastecimento',
                              value: latestFueling != null
                                  ? _formatMoney(latestFueling.fueling.totalValue)
                                  : '—',
                              subtitle: latestFueling != null
                                  ? '#${latestFueling.index}'
                                  : 'Sem registros',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _kpiCard(
                              title: 'Consumo (km/L)',
                              value: latestMeasurable != null
                                  ? '${_formatNum(latestMeasurable.kmPerLiter)} km/L'
                                  : '—',
                              subtitle: 'A partir do 2º',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _kpiCard(
                              title: 'Custo (R\$/km)',
                              value: latestMeasurable != null
                                  ? '${_formatMoney(latestMeasurable.costPerKm)}/km'
                                  : '—',
                              subtitle: 'A partir do 2º',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FuelCharts(metrics: metrics),
                      const SizedBox(height: 16),
                      Text(
                        'Abastecimentos (${metrics.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (metrics.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhum abastecimento registrado ainda.'),
                          ),
                        )
                      else
                        ...metrics.reversed.map((m) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                '#${m.index} • ${m.fueling.fuelType.label} • ${_formatMoney(m.fueling.totalValue)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${_formatDate(m.fueling.dateTime)} • ${m.fueling.odometerKm.toStringAsFixed(0)} km • ${_formatNum(m.fueling.liters)} L',
                              ),
                              trailing: m.hasConsumptionMetrics
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_formatNum(m.kmPerLiter)} km/L',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${_formatMoney(m.costPerKm)}/km',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Referência',
                                      style: TextStyle(fontSize: 12),
                                    ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoVehicleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhum veículo cadastrado',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // const Text(
                //   'Cadastre um veículo consultando marcas e modelos na BrasilAPI para começar a registrar abastecimentos.',
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openVehicleScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar veículo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleHeader(Vehicle vehicle) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car_rounded, size: 32),
        title: Text(
          '${vehicle.brandName} ${vehicle.modelName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Ano ${vehicle.year} • Cilindrada ${vehicle.engineDisplacement}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openVehicleScreen,
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}