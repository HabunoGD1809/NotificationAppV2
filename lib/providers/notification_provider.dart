import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../models/statistics.dart';
import '../config/api_config.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<Notification> _notifications = [];
  List<Notification> _unreadNotifications = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMoreNotifications = true;

  Statistics? _statistics;
  bool _loadingStats = false;
  String? _statsError;

// Getters
  List<Notification> get notifications => _notifications;
  List<Notification> get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreNotifications => _hasMoreNotifications;
  Statistics? get statistics => _statistics;
  bool get loadingStats => _loadingStats;
  String? get statsError => _statsError;

  Future<void> loadNotifications({bool refresh = false}) async {
    // Si ya está cargando o no hay más notificaciones, salir
    if (_isLoading || (!_hasMoreNotifications && !refresh)) return;

    // Marcar como cargando antes de notificar
    _isLoading = true;

    // Solo limpiar y notificar si es un refresh
    if (refresh) {
      _currentPage = 0;
      _hasMoreNotifications = true;
      _notifications = [];
      notifyListeners();
    }

    try {
      final notifications = await _apiService.getNotifications(
        skip: _currentPage * _pageSize,
        limit: _pageSize,
      );

      if (notifications.isEmpty) {
        _hasMoreNotifications = false;
      } else {
        if (refresh) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _currentPage++;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      // Notificar solo una vez al final
      notifyListeners();
    }
  }

  Future<void> loadUnreadNotifications() async {
    try {
      _unreadNotifications = await _apiService.getUnreadNotifications();
      // Notificar solo si hay cambios
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);

// Actualizar listas locales
      _notifications = _notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(leida: true, sonando: false);
        }
        return notification;
      }).toList();

      _unreadNotifications
          .removeWhere((notification) => notification.id == notificationId);

// Detener el sonido de la notificación
      await _notificationService.stopSound(notificationId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> sendNotification(
    String title,
    String message,
    String? imageUrl,
    List<String>? targetDevices,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notification = await _apiService.sendNotification(
        title,
        message,
        imageUrl,
        targetDevices,
      );

      _notifications.insert(0, notification);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Statistics> getStatistics() async {
    _loadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      final stats = await _apiService.getStatistics();
      _statistics = stats; // Almacenamos las estadísticas internamente
      _statsError = null;
      return stats; // Retornamos las estadísticas
    } catch (e) {
      _statsError = e.toString();
      _statistics = null;
      rethrow; // Propagamos el error
    } finally {
      _loadingStats = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getNotificationStats(
      String notificationId) async {
    try {
      final response = await _apiService.get(
        _apiService.buildUrl('/notificaciones/$notificationId/estado'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'total_dispositivos': data['total_dispositivos'] ?? 0,
          'enviadas': data['enviadas'] ?? 0,
          'leidas': data['leidas'] ?? 0,
        };
      }

      throw const HttpException(
          'Error al obtener estadísticas de la notificación');
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  Future<void> resendNotification(String notificationId) async {
    try {
      final response = await _apiService.post(
        _apiService.buildUrl('/notificaciones/$notificationId/reenviar'),
      );

      if (response.statusCode != 200) {
        throw const HttpException('Error al reenviar la notificación');
      }

      // Actualizar estadísticas después del reenvío
      await getStatistics();
    } catch (e) {
      throw Exception('Error al reenviar notificación: ${e.toString()}');
    }
  }

  void handleNewNotification(Notification notification) {
// Agregar a las listas correspondientes
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.insert(0, notification);
    }

    if (!notification.leida &&
        !_unreadNotifications.any((n) => n.id == notification.id)) {
      _unreadNotifications.add(notification);
    }

// Mostrar la notificación local
    _notificationService.showNotification(notification);

    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiService.delete(
        Uri.parse('${ApiConfig.baseUrl}/notificaciones/$notificationId'),
      );

// Eliminar de las listas locales
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);

      notifyListeners();
    } catch (e) {
      throw Exception('Error al eliminar notificación: ${e.toString()}');
    }
  }

  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearStatsError() {
    _statsError = null;
    notifyListeners();
  }
}
