import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fueling.dart';
import '../models/vehicle.dart';

class LocalStorageService {
  static const String _vehicleKey = 'custo_certo_vehicle_v1';
  static const String _fuelingsKey = 'custo_certo_fuelings_v1';
  static const String _darkModeKey = 'custo_certo_dark_mode_v1';


  // salva o veículo único cadastrado
  Future<void> saveVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
  }

  // carrega o veículo único, se existir
  Future<Vehicle?> getVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vehicleKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return Vehicle.fromJson(decoded);
  }

  // exclui o veículo atual e todos os abastecimentos associados a ele
  Future<void> deleteVehicleAndFuelings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleKey);
    await prefs.remove(_fuelingsKey);
  }

  // salva a lista completa de abastecimentos
  Future<void> saveFuelings(List<Fueling> fuelings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(fuelings.map((f) => f.toJson()).toList());
    await prefs.setString(_fuelingsKey, encoded);
  }

  // carrega os abastecimentos ordenados por quilometragem e data
  Future<List<Fueling>> getFuelings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fuelingsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded
        .map((item) => Fueling.fromJson(item as Map<String, dynamic>))
        .toList();

    list.sort((a, b) {
      final kmCompare = a.odometerKm.compareTo(b.odometerKm);
      if (kmCompare != 0) return kmCompare;
      return a.dateTime.compareTo(b.dateTime);
    });

    return list;
  }

  // adiciona um novo abastecimento na persistência local
  Future<List<Fueling>> addFueling(Fueling fueling) async {
    final currentList = await getFuelings();
    currentList.add(fueling);
    currentList.sort((a, b) {
      final kmCompare = a.odometerKm.compareTo(b.odometerKm);
      if (kmCompare != 0) return kmCompare;
      return a.dateTime.compareTo(b.dateTime);
    });
    await saveFuelings(currentList);
    return currentList;
  }

  
  // salva preferência de modo noturno
  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDark);
  }

  // lê preferência de modo noturno (padrão false = azul claro)
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }
}

