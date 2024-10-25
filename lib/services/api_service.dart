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
  DateTime? _lastTokenRefresh;
  bool _isRefreshing = false;

  // Token Management Methods
  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        developer.log('No access token found');
        return null;
      }

      // Verificar si necesitamos refrescar el token
      if (_lastTokenRefresh != null) {
        final difference = DateTime.now().difference(_lastTokenRefresh!);
        if (difference.inMinutes >= 25) { // Refrescar 5 minutos antes de que expire
          return await refreshAccessToken();
        }
      }

      return token;
    } catch (e) {
      developer.log('Error getting access token', error: e);
      return null;
    }
  }

  Future<String?> refreshAccessToken() async {
    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return await getAccessToken();
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw const HttpException('No refresh token available');
      }

      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshToken}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        await _storage.write(key: 'session_id', value: data['session_id']);
        _lastTokenRefresh = DateTime.now();
        return data['access_token'];
      } else {
        await clearTokens();
        throw HttpException('Token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error refreshing token', error: e);
      await clearTokens();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password, Device deviceInfo) async {
    try {
      developer.log('Sending login request');

      final formData = {
        'username': email,
        'password': password,
        'device_id': deviceInfo.deviceId,
        'device_name': deviceInfo.deviceName,
        'modelo': deviceInfo.modelo,
        'sistema_operativo': deviceInfo.sistemaOperativo,
      };

      developer.log('Login request data: $formData');

      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: Uri(queryParameters: formData).query,
      );

      developer.log('Login response status: ${response.statusCode}');
      developer.log('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        await _storage.write(key: 'session_id', value: data['session_id']);
        _lastTokenRefresh = DateTime.now();
        return data;
      }

      final errorBody = jsonDecode(response.body);
      throw HttpException(
          errorBody['detail'] is Map
              ? errorBody['detail']['error'] ?? 'Authentication error'
              : errorBody['detail'] ?? 'Authentication error'
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in login',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is HttpException) rethrow;
      throw HttpException('Connection error: $e');
    }
  }

  // User Methods
  Future<User> getCurrentUser() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.currentUser}'),
      );

      if (response.statusCode == 200) {
        developer.log('Current user obtained: ${response.body}');
        return User.fromJson(jsonDecode(response.body));
      }

      throw const HttpException('Error getting current user');
    } catch (e) {
      developer.log('Error getting current user', error: e);
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      final response = await put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassword}'),
        body: jsonEncode({'nueva_contrasena': newPassword}),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error changing password');
      }
    } catch (e) {
      developer.log('Error changing password', error: e);
      rethrow;
    }
  }

  // Notifications Methods
  Future<List<Notification>> getNotifications({int skip = 0, int limit = 100}) async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}?skip=$skip&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Notification.fromJson(json)).toList();
      }

      throw const HttpException('Error getting notifications');
    } catch (e) {
      developer.log('Error getting notifications', error: e);
      rethrow;
    }
  }

  Future<List<Notification>> getUnreadNotifications() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.unreadNotifications}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Notification.fromJson(json)).toList();
      }

      throw const HttpException('Error getting unread notifications');
    } catch (e) {
      developer.log('Error getting unread notifications', error: e);
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationRead}'.replaceFirst('{notificationId}', notificationId)),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error marking notification as read');
      }
    } catch (e) {
      developer.log('Error marking notification as read', error: e);
      rethrow;
    }
  }

  Future<Notification> sendNotification(String title, String message, String? imageUrl, List<String>? targetDevices) async {
    try {
      final response = await post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}'),
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

      throw const HttpException('Error sending notification');
    } catch (e) {
      developer.log('Error sending notification', error: e);
      rethrow;
    }
  }

  // Statistics Methods
  Future<Statistics> getStatistics() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationStats}'),
      );

      if (response.statusCode == 200) {
        return Statistics.fromJson(jsonDecode(response.body));
      }

      throw const HttpException('Error getting statistics');
    } catch (e) {
      developer.log('Error getting statistics', error: e);
      rethrow;
    }
  }

  // Device Methods
  Future<void> updateDeviceStatus(String deviceId, bool isOnline) async {
    try {
      final response = await put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deviceStatus}'.replaceFirst('{deviceId}', deviceId)),
        body: jsonEncode({'esta_online': isOnline}),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error updating device status');
      }
    } catch (e) {
      developer.log('Error updating device status', error: e);
      rethrow;
    }
  }

  Future<List<Device>> getDevices() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.devices}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Device.fromJson(json)).toList();
      }

      throw const HttpException('Error getting devices');
    } catch (e) {
      developer.log('Error getting devices', error: e);
      rethrow;
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      final response = await delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.devices}/$deviceId'),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error deleting device');
      }
    } catch (e) {
      developer.log('Error deleting device', error: e);
      rethrow;
    }
  }

  // User Management Methods
  Future<List<User>> getUsers() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      }

      throw const HttpException('Error getting users');
    } catch (e) {
      developer.log('Error getting users', error: e);
      rethrow;
    }
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    try {
      final response = await put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resetPassword}/$userId/restablecer_contrasena'),
        body: jsonEncode({'nueva_contrasena': newPassword}),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error resetting password');
      }
    } catch (e) {
      developer.log('Error resetting password', error: e);
      rethrow;
    }
  }

  Future<User> createUser(String name, String email, String password) async {
    try {
      final response = await post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}'),
        body: jsonEncode({
          'nombre': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      throw const HttpException('Error creating user');
    } catch (e) {
      developer.log('Error creating user', error: e);
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.users}/$userId'),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error deleting user');
      }
    } catch (e) {
      developer.log('Error deleting user', error: e);
      rethrow;
    }
  }

  // Sound Settings Methods
  Future<String> getNotificationSound() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.soundSettings}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sonido'];
      }

      throw const HttpException('Error getting sound settings');
    } catch (e) {
      developer.log('Error getting sound settings', error: e);
      rethrow;
    }
  }

  Future<void> setNotificationSound(String sound) async {
    try {
      final response = await post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.soundSettings}'),
        body: jsonEncode({'sonido': sound}),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error updating sound settings');
      }
    } catch (e) {
      developer.log('Error updating sound settings', error: e);
      rethrow;
    }
  }

  // Session Management
  Future<bool> checkActiveSession() async {
    try {
      final sessionId = await _storage.read(key: 'session_id');
      final token = await getAccessToken();

      if (sessionId == null || token == null) {
        return false;
      }

      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}/sesion-activa'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['activa'] == true;
      }

      return false;
    } catch (e) {
      developer.log('Error checking active session', error: e);
      return false;
    }
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: 'session_id');
  }

  // Device Ping
  Future<bool> pingDevice(String sessionId) async {
    try {
      final response = await post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.devicePing}'.replaceFirst('{sessionId}', sessionId)),
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error pinging device', error: e);
      return false;
    }
  }

  // HTTP Request Wrapper Methods with Auto-Refresh
  Future<http.Response> _requestWithRefresh(
      Future<http.Response> Function(String token) request
      ) async {
    try {String? token = await getAccessToken();
    if (token == null) {
      throw const HttpException('No access token available');
    }

    var response = await request(token);

    if (response.statusCode == 401) {
      token = await refreshAccessToken();
      if (token != null) {
        response = await request(token);
      }
    }

    return response;
    } catch (e) {
      developer.log('Request error', error: e);
      rethrow;
    }
  }

  // HTTP Methods with Auto-Refresh
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _requestWithRefresh((token) {
      final finalHeaders = headers ?? {};
      finalHeaders.addAll(ApiConfig.getHeaders(token));
      return _client.get(url, headers: finalHeaders);
    });
  }

  Future<http.Response> post(Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _requestWithRefresh((token) {
      final finalHeaders = headers ?? {};
      finalHeaders.addAll(ApiConfig.getHeaders(token));
      return _client.post(
        url,
        headers: finalHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  Future<http.Response> put(Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _requestWithRefresh((token) {
      final finalHeaders = headers ?? {};
      finalHeaders.addAll(ApiConfig.getHeaders(token));
      return _client.put(
        url,
        headers: finalHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    return _requestWithRefresh((token) {
      final finalHeaders = headers ?? {};
      finalHeaders.addAll(ApiConfig.getHeaders(token));
      return _client.delete(url, headers: finalHeaders);
    });
  }

  // Helper Methods
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

  // Token Storage Methods
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (e) {
      developer.log('Error getting refresh token', error: e);
      return null;
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'session_id');
      _lastTokenRefresh = null;
    } catch (e) {
      developer.log('Error clearing tokens', error: e);
    }
  }

  // Retry Mechanism for Critical Operations
  Future<T> retryOperation<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxAttempts) {
          rethrow;
        }
        developer.log('Operation failed, attempt $attempts of $maxAttempts', error: e);
        await Future.delayed(delay * attempts);
      }
    }
  }

  // Error Handling Helper
  void handleError(String operation, dynamic error) {
    developer.log(
      'Error in $operation',
      error: error,
      stackTrace: error is Error ? error.stackTrace : StackTrace.current,
    );
  }

  // Websocket Support Methods
  Future<bool> isWebSocketConnected(String sessionId) async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}/websocket-status/$sessionId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['connected'] == true;
      }
      return false;
    } catch (e) {
      developer.log('Error checking WebSocket status', error: e);
      return false;
    }
  }

  // Background Tasks Helper
  Future<bool> checkBackgroundTasks() async {
    try {
      final response = await get(
        Uri.parse('${ApiConfig.baseUrl}/background-tasks-status'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tasks_running'] == true;
      }
      return false;
    } catch (e) {
      developer.log('Error checking background tasks', error: e);
      return false;
    }
  }

  // Resource Cleanup
  void dispose() {
    _client.close();
  }

  // Sistema de Health Check
  Future<bool> checkServerHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: {'Accept': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error checking server health', error: e);
      return false;
    }
  }

  // Monitor de Conexión
  Future<Map<String, dynamic>> getConnectionStatus() async {
    try {
      final sessionId = await getSessionId();
      final wsConnected = sessionId != null ? await isWebSocketConnected(sessionId) : false;
      final serverHealthy = await checkServerHealth();
      final hasValidToken = await getAccessToken() != null;

      return {
        'websocket_connected': wsConnected,
        'server_healthy': serverHealthy,
        'has_valid_token': hasValidToken,
        'session_active': sessionId != null,
        'last_token_refresh': _lastTokenRefresh?.toIso8601String(),
      };
    } catch (e) {
      developer.log('Error getting connection status', error: e);
      return {
        'websocket_connected': false,
        'server_healthy': false,
        'has_valid_token': false,
        'session_active': false,
        'error': e.toString(),
      };
    }
  }
}