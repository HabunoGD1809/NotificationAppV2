import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiHelper {
  static Future<dynamic> handleResponse(http.Response response) async {
    switch (response.statusCode) {
    case 200:
    case 201:
    return json.decode(response.body);
    case 400:
    throw Exception(
    _parseErrorMessage(response) ?? 'Error en la solicitud',
    );
    case 401:
    throw Exception('No autorizado');
    case 403:
    throw Exception('Acceso denegado');
    case 404:
    throw Exception('Recurso no encontrado');
    case 500:
    throw Exception('Error interno del servidor');
    default:
    throw Exception(          _parseErrorMessage(response) ??
        'Error desconocido: ${response.statusCode}',
    );
    }
  }

  static String? _parseErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body['detail'] ?? body['message'] ?? body['error'];
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Uri buildUrl(String path, [Map<String, dynamic>? queryParams]) {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');

    if (queryParams != null) {
      final queryString = queryParams.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      if (queryString.isNotEmpty) {
        uri = Uri.parse('$uri?$queryString');
      }
    }

    return uri;
  }

  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.baseUrl))
          .timeout(ApiConfig.connectionTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}