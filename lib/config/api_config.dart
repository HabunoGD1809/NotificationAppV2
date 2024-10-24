class ApiConfig {
  // Para emulador Android
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String wsUrl = 'ws://10.0.2.2:8000';

  // Auth endpoints
  static const String login = '/token';
  static const String refreshToken = '/token/refresh';

  // User endpoints
  static const String users = '/usuarios';
  static const String changePassword = '/usuarios/cambiar_contrasena';
  static const String resetPassword = '/usuarios';
  static const String currentUser = '/usuarios/me';

  // Device endpoints
  static const String devices = '/dispositivos';
  static const String deviceStatus = '/dispositivos/{deviceId}/online';
  static const String devicePing = '/dispositivos/{sessionId}/ping';

  // Notification endpoints
  static const String notifications = '/notificaciones';
  static const String notificationStatus = '/notificaciones/{notificationId}/estado';
  static const String notificationRead = '/notificaciones/{notificationId}/leer';
  static const String unreadNotifications = '/notificaciones/no-leidas';
  static const String notificationStats = '/notificaciones/estadisticas';

  // WebSocket endpoint
  static const String wsEndpoint = '/ws/{sessionId}';

  // Sound settings
  static const String soundSettings = '/usuarios/configuracion-sonido';

  // Session
  static const String activeSession = '/sesion-activa';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}