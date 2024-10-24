import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/device.dart';
import 'dart:developer' as developer;


class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> isAuthenticated() async {
    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        await _getCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log('Iniciando login para email: $email');

      // Obtener información del dispositivo
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      developer.log('Información del dispositivo obtenida');

      // Crear el mapa de información del dispositivo
      final deviceInfoMap = {
        'device_id': deviceInfo.id,
        'device_name': deviceInfo.model ?? 'Dispositivo Android',
        'modelo': deviceInfo.model ?? 'Desconocido',
        'sistema_operativo': 'Android ${deviceInfo.version.release}'
      };

      developer.log('Device info: $deviceInfoMap');

      final response = await _apiService.login(
          email,
          password,
          deviceInfoMap
      );

      // Verificar que la respuesta tenga la estructura esperada
      if (response['user_info'] != null) {
        _currentUser = User.fromJson(response['user_info']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Respuesta del servidor inválida');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error en login',
        error: e,
        stackTrace: stackTrace,
      );
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.clearTokens();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.changePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}