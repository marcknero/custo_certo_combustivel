import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiOption {
  final String code;
  final String name;

  const ApiOption({
    required this.code,
    required this.name,
  });
}

class BrasilApiService {
  static const String _baseUrl = 'https://brasilapi.com.br/api/fipe';

  // busca marcas conforme o tipo de veículo (carros, motos, caminhoes)
  Future<List<ApiOption>> fetchBrands({String vehicleType = 'carros'}) async {
    final uri = Uri.parse('$_baseUrl/marcas/v1/$vehicleType');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar marcas (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Formato inesperado retornado pela BrasilAPI.');
    }

    return decoded
        .map((item) {
          final map = item as Map<String, dynamic>;
          final code = (map['valor'] ?? map['codigo'] ?? '').toString().trim();
          final name = (map['nome'] ?? '').toString().trim();
          return ApiOption(code: code, name: name);
        })
        .where((opt) => opt.code.isNotEmpty && opt.name.isNotEmpty)
        .toList();
  }

  // busca modelos de uma marca específica
  Future<List<ApiOption>> fetchModelsByBrand({
    required String brandCode,
    String vehicleType = 'carros',
  }) async {
    final uri = Uri.parse('$_baseUrl/veiculos/v1/$vehicleType/$brandCode');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar modelos (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);

    // a brasilapi pode retornar lista direta ou objeto contendo lista de modelos
    List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['modelos'] is List) {
      rawList = decoded['modelos'] as List<dynamic>;
    } else {
      throw Exception('Formato inesperado de modelos na BrasilAPI.');
    }

    return rawList
        .map((item) {
          final map = item as Map<String, dynamic>;
          final code = (map['valor'] ?? map['codigo'] ?? '').toString().trim();
          final name = (map['nome'] ?? map['modelo'] ?? '').toString().trim();
          return ApiOption(code: code, name: name);
        })
        .where((opt) => opt.code.isNotEmpty && opt.name.isNotEmpty)
        .toList();
  }
}