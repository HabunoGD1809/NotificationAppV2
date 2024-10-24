class AppConstants {
  // Nombres de rutas
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String notificationsRoute = '/notifications';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String adminDashboardRoute = '/admin/dashboard';
  static const String adminUsersRoute = '/admin/users';
  static const String adminStatisticsRoute = '/admin/statistics';

  // Preferencias
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String sessionIdKey = 'session_id';
  static const String themeKey = 'theme_mode';
  static const String soundSettingsKey = 'sound_settings';

  // Timeouts y reintentos
  static const int connectionTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 5;

  // Paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validación
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 32;
  static const int maxTitleLength = 100;
  static const int maxMessageLength = 500;
  static const int maxDeviceNameLength = 50;

  // Notificaciones
  static const String notificationChannelId = 'notification_app_channel';
  static const String notificationChannelName = 'Notificaciones';
  static const String notificationChannelDescription =
      'Canal para notificaciones de la aplicación';

  // WebSocket
  static const int pingInterval = 30;  // segundos
  static const int reconnectDelay = 5;  // segundos
  static const int maxReconnectAttempts = 5;

  // Sonidos
  static const String defaultNotificationSound = 'default.mp3';
  static const List<String> availableNotificationSounds = [
    'default.mp3',
    'alert.mp3',
    'bell.mp3',
    'chime.mp3',
    'notification.mp3',
  ];

  // Estados de dispositivos
  static const int deviceInactiveThreshold = 15;  // minutos

  // Mensajes de error
  static const String networkError =
      'No se pudo conectar con el servidor. Por favor, verifica tu conexión.';
  static const String unexpectedError =
      'Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo.';
  static const String sessionExpired =
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
  static const String permissionDenied =
      'No tienes permisos para realizar esta acción.';
  static const String invalidCredentials =
      'Credenciales inválidas. Por favor, verifica tus datos.';

  // Mensajes de éxito
  static const String loginSuccess = '¡Bienvenido!';
  static const String notificationSent = 'Notificación enviada exitosamente';
  static const String settingsSaved = 'Configuración guardada exitosamente';
  static const String passwordChanged = 'Contraseña actualizada exitosamente';

  // Assets
  static const String logoPath = 'assets/images/logo.png';
  static const String soundsPath = 'assets/sounds/notification_sounds/';
  static const String placeholderImagePath = 'assets/images/placeholder.png';
}