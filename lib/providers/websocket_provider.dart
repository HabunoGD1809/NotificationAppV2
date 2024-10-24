import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  bool _isConnected = false;
  String? _error;

  bool get isConnected => _isConnected;
  String? get error => _error;

  void initialize() {
    _webSocketService.notificationStream.listen(
          (notification) {
        // Notificar a los listeners sobre la nueva notificación
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  Future<void> connect(String sessionId) async {
    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        await _webSocketService.connect(sessionId, token);
        _isConnected = true;
        _error = null;
      } else {
        throw Exception('No se encontró token de acceso');
      }
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      _isConnected = false;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> reconnect(String sessionId) async {
    await disconnect();
    await connect(sessionId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}