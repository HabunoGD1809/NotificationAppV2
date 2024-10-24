import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  final ApiService _apiService = ApiService();
  final StreamController<Notification> _notificationController = StreamController<Notification>.broadcast();
  bool _isConnected = false;
  String? _sessionId;
  final Duration _pingInterval = const Duration(seconds: 30);
  final Duration _reconnectInterval = const Duration(seconds: 5);

  Stream<Notification> get notificationStream => _notificationController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String sessionId, String token) async {
    if (_channel != null) {
      await disconnect();
    }

    _sessionId = sessionId;
    final wsUrl = '${ApiConfig.wsUrl}${ApiConfig.wsEndpoint}'
        .replaceFirst('{sessionId}', sessionId)
        .replaceFirst('http', 'ws');

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );

      _isConnected = true;
      _startPingTimer();

      _channel!.stream.listen(
            (message) => _handleMessage(message),
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      switch (data['tipo']) {
        case 'nueva_notificacion':
        case 'notificacion_pendiente':
          final notification = Notification.fromJson(data['notificacion']);
          _notificationController.add(notification);
          break;
        case 'ping':
          _sendPong();
          break;
        case 'sesion_cerrada':
          disconnect();
          break;
      }
    } catch (e) {
      print('Error al procesar mensaje WebSocket: $e');
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  void _sendPing() {
    try {
      _channel?.sink.add(jsonEncode({'tipo': 'ping'}));
    } catch (e) {
      print('Error al enviar ping: $e');
    }
  }

  void _sendPong() {
    try {
      _channel?.sink.add(jsonEncode({'tipo': 'pong'}));
    } catch (e) {
      print('Error al enviar pong: $e');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () async {
      if (!_isConnected && _sessionId != null) {
        try {
          final token = await _apiService.getAccessToken();
          if (token != null) {
            await connect(_sessionId!, token);
          }
        } catch (e) {
          print('Error en reconexión: $e');
          _scheduleReconnect();
        }
      }
    });
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
  }
}