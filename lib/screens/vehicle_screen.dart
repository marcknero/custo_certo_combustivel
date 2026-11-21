import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/brasil_api_service.dart';
import '../services/local_storage_service.dart';

class VehicleScreen extends StatefulWidget {
  final Vehicle? existingVehicle;
  final LocalStorageService storageService;

  const VehicleScreen({
    super.key,
    required this.existingVehicle,
    required this.storageService,
  });

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brasilApi = BrasilApiService();

  final _yearController = TextEditingController();
  final _engineController = TextEditingController();
  final _manualModelController = TextEditingController();

  String _vehicleType = 'carros';
  List<ApiOption> _brands = [];
  List<ApiOption> _models = [];
  ApiOption? _selectedBrand;
  ApiOption? _selectedModel;

  bool _loadingBrands = false;
  bool _loadingModels = false;
  bool _saving = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    if (widget.existingVehicle != null) {
      _yearController.text = widget.existingVehicle!.year.toString();
      _engineController.text = widget.existingVehicle!.engineDisplacement;
    } else {
      _loadBrands();
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _engineController.dispose();
    _manualModelController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _apiError = null;
      _selectedBrand = null;
      _selectedModel = null;
      _models = [];
    });

    try {
      final brands = await _brasilApi.fetchBrands(vehicleType: _vehicleType);
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _loadingBrands = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBrands = false;
        _apiError = 'Não foi possível consultar marcas na BrasilAPI. Você pode tentar novamente.';
      });
    }
  }

  Future<void> _onBrandChanged(ApiOption? brand) async {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _models = [];
      _manualModelController.clear();
      _apiError = null;
    });

    if (brand == null) return;

    setState(() => _loadingModels = true);
    try {
      final models = await _brasilApi.fetchModelsByBrand(
        brandCode: brand.code,
        vehicleType: _vehicleType,
      );
      if (!mounted) return;
      setState(() {
        _models = models;
        _loadingModels = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingModels = false;
        _apiError = 'Erro ao buscar modelos da marca selecionada. Digite o modelo manualmente se preferir.';
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrand == null) {
      _showMessage('Selecione a marca do veículo.');
      return;
    }

    final modelName = _selectedModel?.name ?? _manualModelController.text.trim();
    if (modelName.isEmpty) {
      _showMessage('Selecione ou informe o modelo do veículo.');
      return;
    }

    final year = int.parse(_yearController.text.trim());
    final engine = _engineController.text.trim();

    setState(() => _saving = true);

    final vehicle = Vehicle(
      brandCode: _selectedBrand!.code,
      brandName: _selectedBrand!.name,
      modelCode: _selectedModel?.code ?? 'custom',
      modelName: modelName,
      year: year,
      engineDisplacement: engine,
    );

    await widget.storageService.saveVehicle(vehicle);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmAndDeleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir veículo'),
        content: const Text(
          'Deseja realmente excluir o veículo atual? Todos os abastecimentos associados a ele também serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await widget.storageService.deleteVehicleAndFuelings();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final currentVehicle = widget.existingVehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentVehicle != null ? 'Veículo cadastrado' : 'Cadastrar veículo'),
      ),
      body: currentVehicle != null
          ? _buildExistingVehicleView(currentVehicle)
          : _buildRegisterFormView(),
    );
  }

  Widget _buildExistingVehicleView(Vehicle vehicle) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      '${vehicle.brandName} ${vehicle.modelName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _infoRow('Marca', vehicle.brandName),
                _infoRow('Modelo', vehicle.modelName),
                _infoRow('Ano', vehicle.year.toString()),
                _infoRow('Cilindrada', vehicle.engineDisplacement),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apenas um veículo pode ficar ativo por vez. Para cadastrar outro, exclua o veículo atual (os abastecimentos vinculados também serão apagados).',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmAndDeleteVehicle,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir veículo e abastecimentos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildRegisterFormView() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dados do veículo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _vehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Categoria FIPE',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'carros', child: Text('Carros')),
                      DropdownMenuItem(value: 'motos', child: Text('Motos')),
                      DropdownMenuItem(value: 'caminhoes', child: Text('Caminhões')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _vehicleType = value);
                      _loadBrands();
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_loadingBrands)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<ApiOption>(
                      initialValue: _selectedBrand,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Marca (BrasilAPI)',
                        border: OutlineInputBorder(),
                      ),
                      items: _brands
                          .map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: _onBrandChanged,
                    ),
                  const SizedBox(height: 14),
                  if (_loadingModels)
                    const LinearProgressIndicator()
                  else if (_models.isNotEmpty)
                    DropdownButtonFormField<ApiOption>(
                      initialValue: _selectedModel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Modelo (filtrados pela marca)',
                        border: OutlineInputBorder(),
                      ),
                      items: _models
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedModel = val),
                    )
                  else
                    TextFormField(
                      controller: _manualModelController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo do veículo',
                        hintText: 'Ex.: Onix 1.0 Turbo ou CG 160',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (_apiError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _apiError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ano',
                            hintText: 'Ex.: 2022',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final year = int.tryParse((value ?? '').trim());
                            if (year == null || year < 1950 || year > 2027) {
                              return 'Ano inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _engineController,
                          decoration: const InputDecoration(
                            labelText: 'Cilindrada',
                            hintText: 'Ex.: 1.0, 2.0, 160cc',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Informe a cilindrada';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveVehicle,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Salvando...' : 'Salvar veículo'),
            ),
          ),
        ],
      ),
    );
  }
}