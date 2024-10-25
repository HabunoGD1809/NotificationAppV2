import 'dart:io';
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
  bool _isInitialized = false;
  Future<bool>? _authenticationCheck;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> isAuthenticated() async {
    // Si ya hay una verificación en curso, retornarla
    if (_authenticationCheck != null) {
      return _authenticationCheck!;
    }

    // Si ya está inicializado, retornar el estado actual
    if (_isInitialized) {
      return _currentUser != null;
    }

    // Crear una nueva verificación
    _authenticationCheck = _checkAuthentication();
    final result = await _authenticationCheck!;
    _authenticationCheck = null;
    return result;
  }

  Future<bool> _checkAuthentication() async {
    try {
      developer.log('Verificando autenticación');
      final token = await _apiService.getAccessToken();
      developer.log('Token obtenido: $token');

      if (token != null) {
        try {
          _currentUser = await _apiService.getCurrentUser();
          _isInitialized = true;
          notifyListeners();
          return true;
        } catch (e) {
          developer.log('Error al obtener usuario actual', error: e);
          await _apiService.clearTokens();
          _isInitialized = true;
          notifyListeners();
          return false;
        }
      }

      _isInitialized = true;
      notifyListeners();
      return false;
    } catch (e) {
      developer.log('Error en autenticación', error: e);
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log('Iniciando login para email: $email');

      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      developer.log('Información del dispositivo obtenida');

      final device = Device(
        id: '',
        deviceId: deviceInfo.id,
        deviceName: deviceInfo.model,
        modelo: deviceInfo.model,
        sistemaOperativo: 'Android ${deviceInfo.version.release}',
        estaOnline: true,
        ultimoAcceso: DateTime.now(),
      );

      final response = await _apiService.login(email, password, device);

      if (response.containsKey('user_info')) {
        _currentUser = User.fromJson(response['user_info']);
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        developer.log('Login completado exitosamente');
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

      if (e is HttpException) {
        _error = e.message;
      } else {
        _error = 'Error de conexión. Por favor, verifica tu conexión a internet.';
      }

      _isLoading = false;
      notifyListeners();
      return false;
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

  Future<void> logout() async {
    try {
      await _apiService.clearTokens();
      _currentUser = null;
      _isInitialized = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}