import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/api_service.dart';
import '../models/device.dart';

class DeviceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Device> _devices = [];
  Device? _currentDevice;
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => _devices;
  Device? get currentDevice => _currentDevice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _devices = await _apiService.getDevices();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeCurrentDevice() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final deviceId = deviceInfo.id;

      _currentDevice = _devices.firstWhere(
            (device) => device.deviceId == deviceId,
        orElse: () => Device(
          id: '',
          deviceId: deviceId,
          deviceName: deviceInfo.model,
          modelo: deviceInfo.model,
          sistemaOperativo: 'Android ${deviceInfo.version.release}',
          estaOnline: true,
          ultimoAcceso: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDeviceStatus(String deviceId, bool isOnline) async {
    try {
      await _apiService.updateDeviceStatus(deviceId, isOnline);

      _devices = _devices.map((device) {
        if (device.id == deviceId) {
          return device.copyWith(
            estaOnline: isOnline,
            ultimoAcceso: DateTime.now(),
          );
        }
        return device;
      }).toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pingDevice() async {
    if (_currentDevice?.sessionId == null) return;

    try {
      await _apiService.pingDevice(_currentDevice!.sessionId!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      await _apiService.deleteDevice(deviceId);
      _devices.removeWhere((device) => device.id == deviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void updateDeviceSessionId(String sessionId) {
    if (_currentDevice != null) {
      _currentDevice = _currentDevice!.copyWith(sessionId: sessionId);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}