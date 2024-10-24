import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final apiService = ApiService();
    final webSocketService = WebSocketService();
    final notificationService = NotificationService();
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    try {
      final token = await apiService.getAccessToken();
      final sessionId = await apiService.getSessionId();

      if (token != null && sessionId != null && !webSocketService.isConnected) {
        await webSocketService.connect(sessionId, token);
      }

      if (sessionId != null) {
        await apiService.pingDevice(sessionId);
      }
    } catch (e) {
      print('Error en el servicio en segundo plano: $e');
    }

    // Escuchar notificaciones entrantes
    webSocketService.notificationStream.listen((notification) async {
      await notificationService.showNotification(notification);
    });

    return Future.value(true);
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> initialize() async {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    // Programar la tarea para que se ejecute cada minuto
    Workmanager().registerPeriodicTask(
      "1",
      "simplePeriodicTask",
      frequency: const Duration(minutes: 1),
    );

    // Crear el canal de notificación
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'notification_app_service',
      'Background Service',
      description: 'This channel is used for background service notification',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
