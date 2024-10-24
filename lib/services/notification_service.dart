import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification.dart' as model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, Timer> _soundTimers = {};

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Crear el canal de notificación para el servicio
    const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
      'notification_app_service',
      'Servicio de Notificaciones',
      description: 'Canal para el servicio en segundo plano',
      importance: Importance.high,
      enableVibration: false,
      showBadge: false,
    );

    // Crear el canal de notificación para las notificaciones normales
    const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
      'notification_app_channel',
      'Notificaciones',
      description: 'Canal para notificaciones de la aplicación',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(serviceChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(notificationChannel);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        _handleNotificationTap(response.payload);
      },
    );

    // Solicitar permisos en iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showNotification(model.Notification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'notification_app_channel',
      'Notificaciones',
      channelDescription: 'Canal para notificaciones de la aplicación',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.titulo,
      notification.mensaje,
      details,
      payload: notification.id,
    );

    if (notification.sonando) {
      await _startSound(notification);
    }
  }

  Future<void> _startSound(model.Notification notification) async {
    await stopSound(notification.id);

    _soundTimers[notification.id] = Timer.periodic(
      const Duration(seconds: 5),
          (timer) async {
        if (!notification.leida) {
          try {
            await _audioPlayer.play(AssetSource('sounds/notification_sounds/default.mp3'));
          } catch (e) {
            print('Error al reproducir sonido: $e');
          }
        } else {
          timer.cancel();
          _soundTimers.remove(notification.id);
        }
      },
    );
  }

  Future<void> stopSound(String notificationId) async {
    _soundTimers[notificationId]?.cancel();
    _soundTimers.remove(notificationId);
    await _audioPlayer.stop();
  }

  Future<void> stopAllSounds() async {
    for (var timer in _soundTimers.values) {
      timer.cancel();
    }
    _soundTimers.clear();
    await _audioPlayer.stop();
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      // Implementar la navegación a la pantalla de detalles
    }
  }

  Future<void> clearAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    await stopAllSounds();
  }

  void dispose() {
    stopAllSounds();
    _audioPlayer.dispose();
  }
}