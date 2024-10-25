import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  bool _isConnected = false;
  String? _error;
  String? _connectionState;

  bool get isConnected => _isConnected;
  String? get error => _error;
  String? get connectionState => _connectionState;

  void initialize() {
    // Escuchar notificaciones
    _webSocketService.notificationStream.listen(
          (notification) {
        notifyListeners();
      },
      onError: (error) {
        _handleError(error.toString());
      },
    );

    // Escuchar estados de conexión
    _webSocketService.connectionStateStream.listen(
          (state) {
        _handleConnectionState(state);
      },
      onError: (error) {
        _handleError(error.toString());
      },
    );
  }

  void _handleConnectionState(String state) {
    _connectionState = state;
    _isConnected = state == 'connected';

    switch (state) {
      case 'session_closed':
        _error = 'La sesión ha sido cerrada desde otro dispositivo';
        break;
      case 'max_reconnect_attempts_reached':
        _error = 'No se pudo restablecer la conexión después de varios intentos';
        break;
      case 'token_refresh_failed':
        _error = 'Error al actualizar el token de acceso';
        break;
      default:
        _error = null;
    }

    notifyListeners();
  }

  void _handleError(String errorMessage) {
    _error = errorMessage;
    _isConnected = false;
    notifyListeners();
  }

  Future<void> connect(String sessionId) async {
    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        await _webSocketService.connect(sessionId, token);
      } else {
        throw Exception('No se encontró token de acceso');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
    } catch (e) {
      _handleError(e.toString());
    }
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