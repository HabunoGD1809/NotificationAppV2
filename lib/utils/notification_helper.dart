import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification.dart' as model;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

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

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> showNotification(model.Notification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'notification_app_channel',
      'Notificaciones',
      channelDescription: 'Canal para notificaciones de la aplicación',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
      interruptionLevel: InterruptionLevel.active,
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
      await _startRepeatingSound(notification);
    }
  }

  Future<void> _startRepeatingSound(model.Notification notification) async {
    // Detener sonido anterior si existe
    await stopSound(notification.id);

    // Configurar el nuevo timer para repetir el sonido
    _soundTimers[notification.id] = Timer.periodic(
      const Duration(seconds: 3),
          (timer) async {
        if (!notification.leida) {
          try {
            await _audioPlayer.play(
              AssetSource('sounds/notification_sounds/default.mp3'),
              volume: 1.0,
            );
          } catch (e) {
            print('Error reproduciendo sonido: $e');
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

  Future<void> clearAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    await stopAllSounds();
  }

  void _onNotificationTap(NotificationResponse response) {
    // Implementar la navegación cuando se toca la notificación
    // Esta función debe ser llamada desde el main.dart
  }

  void dispose() {
    stopAllSounds();
    _audioPlayer.dispose();
  }
}