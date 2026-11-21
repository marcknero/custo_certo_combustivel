import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fueling.dart';
import '../services/local_storage_service.dart';

class FuelingFormScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final double? lastOdometerKm;

  const FuelingFormScreen({
    super.key,
    required this.storageService,
    required this.lastOdometerKm,
  });

  @override
  State<FuelingFormScreen> createState() => _FuelingFormScreenState();
}

class _FuelingFormScreenState extends State<FuelingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();

  FuelType _selectedFuelType = FuelType.gasolina;
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  double _calculatedTotal = 0.0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_recalculateTotal);
    _litersController.addListener(_recalculateTotal);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _odometerController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  double? _parseDecimal(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _recalculateTotal() {
    final price = _parseDecimal(_priceController.text) ?? 0.0;
    final liters = _parseDecimal(_litersController.text) ?? 0.0;
    final nextTotal = (price > 0 && liters > 0) ? price * liters : 0.0;
    if (nextTotal != _calculatedTotal && mounted) {
      setState(() => _calculatedTotal = nextTotal);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _saveFueling() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final price = _parseDecimal(_priceController.text);
    final odometer = _parseDecimal(_odometerController.text);
    final liters = _parseDecimal(_litersController.text);

    if (price == null || odometer == null || liters == null) return;

    setState(() => _saving = true);

    final fueling = Fueling(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fuelType: _selectedFuelType,
      pricePerLiter: price,
      odometerKm: odometer,
      liters: liters,
      dateTime: _selectedDate,
    );

    await widget.storageService.addFueling(fueling);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar abastecimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<FuelType>(
                      initialValue: _selectedFuelType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de combustível',
                        border: OutlineInputBorder(),
                      ),
                      items: FuelType.values
                          .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFuelType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preço por litro (R\$)',
                        hintText: 'Ex.: 5,89 ou 5.89',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = _parseDecimal(v);
                        if (val == null || val <= 0) {
                          return 'Informe um valor maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _litersController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de litros',
                        hintText: 'Ex.: 40,5 ou 40.5',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = _parseDecimal(v);
                        if (val == null || val <= 0) {
                          return 'Informe a litragem abastecida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _odometerController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quilometragem atual (km)',
                        hintText: widget.lastOdometerKm != null
                            ? 'Maior que ${widget.lastOdometerKm!.toStringAsFixed(0)} km'
                            : 'Ex.: 45200',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = _parseDecimal(v);
                        if (val == null || val < 0) {
                          return 'Informe uma quilometragem válida';
                        }
                        if (widget.lastOdometerKm != null && val <= widget.lastOdometerKm!) {
                          return 'Deve ser maior que ${widget.lastOdometerKm!.toStringAsFixed(0)} km';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Data do abastecimento'),
                      subtitle: Text(dateFmt.format(_selectedDate)),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor total calculado',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      currencyFmt.format(_calculatedTotal),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveFueling,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando...' : 'Salvar abastecimento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}