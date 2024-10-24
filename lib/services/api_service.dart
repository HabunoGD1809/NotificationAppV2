import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/device.dart';
import '../models/notification.dart';
import '../models/statistics.dart';
import 'dart:developer' as developer;


class ApiService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Auth Methods
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      Map<String, dynamic> deviceInfo
      ) async {
    try {
      developer.log('Enviando solicitud de login al servidor');

      // Crear los datos del formulario
      final formData = {
        'username': email,
        'password': password,
      };

      // Agregar device_info como un campo adicional en JSON
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: {
          ...formData,
          'device_info': jsonEncode(deviceInfo),
        }).query,
      );

      developer.log('Respuesta recibida: ${response.statusCode}');
      developer.log('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        if (data['session_id'] != null) {
          await _storage.write(key: 'session_id', value: data['session_id']);
        }
        return data;
      }

      final error = jsonDecode(response.body);
      if (error['detail'] is List) {
        throw HttpException(error['detail'][0]['msg']);
      }
      throw HttpException(error['detail'] ?? 'Error de autenticación');

    } catch (e, stackTrace) {
      developer.log(
        'Error en login',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshToken}'),
        headers: ApiConfig.getHeaders(null),
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        return data;
      }

      throw const HttpException('Error al refrescar el token');
    } catch (e) {
      rethrow;
    }
  }

  // User Methods
  Future<User> getCurrentUser() async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.currentUser}'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }

    throw const HttpException('Error al obtener usuario actual');
  }

  Future<void> changePassword(String newPassword) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassword}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode({'nueva_contrasena': newPassword}),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al cambiar contraseña');
    }
  }

  // Notifications Methods
  Future<List<Notification>> getNotifications({int skip = 0, int limit = 100}) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}?skip=$skip&limit=$limit'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Notification.fromJson(json)).toList();
    }

    throw const HttpException('Error al obtener notificaciones');
  }

  Future<List<Notification>> getUnreadNotifications() async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.unreadNotifications}'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Notification.fromJson(json)).toList();
    }

    throw const HttpException('Error al obtener notificaciones no leídas');
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationRead}'.replaceFirst('{notificationId}', notificationId)),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al marcar notificación como leída');
    }
  }

  Future<Notification> sendNotification(String title, String message, String? imageUrl, List<String>? targetDevices) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode({
        'titulo': title,
        'mensaje': message,
        'imagen_url': imageUrl,
        'dispositivos_objetivo': targetDevices,
      }),
    );

    if (response.statusCode == 200) {
      return Notification.fromJson(jsonDecode(response.body));
    }

    throw const HttpException('Error al enviar notificación');
  }

  // Statistics Methods
  Future<Statistics> getStatistics() async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationStats}'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return Statistics.fromJson(jsonDecode(response.body));
    }

    throw const HttpException('Error al obtener estadísticas');
  }

  // Device Methods
  Future<void> updateDeviceStatus(String deviceId, bool isOnline) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deviceStatus}'.replaceFirst('{deviceId}', deviceId)),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode({'esta_online': isOnline}),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al actualizar estado del dispositivo');
    }
  }

  Future<List<User>> getUsers() async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }

    throw const HttpException('Error al obtener usuarios');
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resetPassword}/$userId/restablecer_contrasena'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode({'nueva_contrasena': newPassword}),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al restablecer contraseña');
    }
  }

  Future<User> createUser(String name, String email, String password) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode({
        'nombre': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }

    throw const HttpException('Error al crear usuario');
  }

  Future<void> deleteUser(String userId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}/$userId'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al eliminar usuario');
    }
  }

  // Session Methods
  Future<String?> getSessionId() async {
    return await _storage.read(key: 'session_id');
  }

  // Device Management Methods
  Future<List<Device>> getDevices() async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.devices}'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    }

    throw const HttpException('Error al obtener dispositivos');
  }

  Future<void> deleteDevice(String deviceId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.devices}/$deviceId'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al eliminar dispositivo');
    }
  }

  // Sound Settings Methods
  Future<String> getNotificationSound() async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.soundSettings}'),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['sonido'];
    }

    throw const HttpException('Error al obtener configuración de sonido');
  }

  Future<void> setNotificationSound(String sound) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.soundSettings}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode({'sonido': sound}),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al actualizar configuración de sonido');
    }
  }

  Future<void> pingDevice(String sessionId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.devicePing}'.replaceFirst('{sessionId}', sessionId)),
      headers: ApiConfig.getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw const HttpException('Error al hacer ping al dispositivo');
    }
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final token = await _storage.read(key: 'access_token');
    final finalHeaders = headers ?? {};
    finalHeaders.addAll(ApiConfig.getHeaders(token));

    return await _client.get(url, headers: finalHeaders);
  }

  Future<http.Response> post(Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await _storage.read(key: 'access_token');
    final finalHeaders = headers ?? {};
    finalHeaders.addAll(ApiConfig.getHeaders(token));

    return await _client.post(
      url,
      headers: finalHeaders,
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> put(Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await _storage.read(key: 'access_token');
    final finalHeaders = headers ?? {};
    finalHeaders.addAll(ApiConfig.getHeaders(token));

    return await _client.put(
      url,
      headers: finalHeaders,
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    final token = await _storage.read(key: 'access_token');
    final finalHeaders = headers ?? {};
    finalHeaders.addAll(ApiConfig.getHeaders(token));

    return await _client.delete(url, headers: finalHeaders);
  }

  // Método helper para construir URLs
  Uri buildUrl(String path, [Map<String, dynamic>? queryParams]) {
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

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'session_id');
  }

}