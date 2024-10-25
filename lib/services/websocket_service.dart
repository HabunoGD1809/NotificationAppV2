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
  Timer? _connectionCheckTimer;
  final ApiService _apiService = ApiService();
  final StreamController<Notification> _notificationController = StreamController<Notification>.broadcast();
  final StreamController<String> _connectionStateController = StreamController<String>.broadcast();
  bool _isConnected = false;
  String? _sessionId;
  String? _lastToken;
  DateTime? _lastPongReceived;
  final Duration _pingInterval = const Duration(seconds: 30);
  final Duration _reconnectInterval = const Duration(seconds: 5);
  final Duration _connectionCheckInterval = const Duration(seconds: 45);
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  Stream<Notification> get notificationStream => _notificationController.stream;
  Stream<String> get connectionStateStream => _connectionStateController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String sessionId, String token) async {
    if (_channel != null) {
      await disconnect();
    }

    _sessionId = sessionId;
    _lastToken = token;
    final wsUrl = '${ApiConfig.wsUrl}${ApiConfig.wsEndpoint}'
        .replaceFirst('{sessionId}', sessionId)
        .replaceFirst('http', 'ws');

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _startPingTimer();
      _startConnectionCheckTimer();
      _connectionStateController.add('connected');

      _channel!.stream.listen(
            (message) => _handleMessage(message),
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      // Realizar ping al endpoint HTTP
      await _apiService.pingDevice(sessionId);
    } catch (e) {
      print('Error establishing WebSocket connection: $e');
      _handleDisconnection();
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
        case 'pong':
          _lastPongReceived = DateTime.now();
          break;
        case 'sesion_cerrada':
          _handleSessionClosed(data['mensaje']);
          break;
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
  }

  void _handleSessionClosed(String message) {
    _connectionStateController.add('session_closed: $message');
    disconnect();
  }

  void _handleDisconnection() {
    _isConnected = false;
    _connectionStateController.add('disconnected');
    _scheduleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  void _startConnectionCheckTimer() {
    _connectionCheckTimer?.cancel();
    _lastPongReceived = DateTime.now();

    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (timer) {
      if (_isConnected && _lastPongReceived != null) {
        final timeSinceLastPong = DateTime.now().difference(_lastPongReceived!);
        if (timeSinceLastPong > _connectionCheckInterval) {
          print('No pong received in ${timeSinceLastPong.inSeconds} seconds');
          _handleDisconnection();
        }
      }
    });
  }

  void _sendPing() {
    try {
      if (_channel?.sink != null && _isConnected) {
        _channel!.sink.add(jsonEncode({'tipo': 'ping'}));
      }
    } catch (e) {
      print('Error sending ping: $e');
      _handleDisconnection();
    }
  }

  void _sendPong() {
    try {
      if (_channel?.sink != null && _isConnected) {
        _channel!.sink.add(jsonEncode({'tipo': 'pong'}));
      }
    } catch (e) {
      print('Error sending pong: $e');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _connectionStateController.add('max_reconnect_attempts_reached');
      return;
    }

    _reconnectTimer = Timer(_reconnectInterval, () async {
      if (!_isConnected && _sessionId != null && _lastToken != null) {
        _reconnectAttempts++;
        try {
          final token = await _apiService.refreshAccessToken();
          if (token != null) {
            await connect(_sessionId!, token);
          } else {
            _connectionStateController.add('token_refresh_failed');
          }
        } catch (e) {
          print('Reconnection error: $e');
          _scheduleReconnect();
        }
      }
    });
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();

    if (_channel != null) {
      try {
        await _channel!.sink.close(status.normalClosure);
      } catch (e) {
        print('Error closing WebSocket channel: $e');
      }
      _channel = null;
    }

    _connectionStateController.add('disconnected');
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _connectionStateController.close();
  }
}