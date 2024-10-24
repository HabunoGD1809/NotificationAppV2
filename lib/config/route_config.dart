import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/notification_list_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/send_notification_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/statistics_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/settings/sound_settings_screen.dart';

class RouteConfig {
  static const String login = '/login';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String adminDashboard = '/admin/dashboard';
  static const String sendNotification = '/admin/send-notification';
  static const String userManagement = '/admin/users';
  static const String statistics = '/admin/statistics';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String resetPassword = '/reset-password';
  static const String soundSettings = '/settings/sound';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConfig.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case RouteConfig.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RouteConfig.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationListScreen());

      case RouteConfig.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case RouteConfig.sendNotification:
        return MaterialPageRoute(builder: (_) => const SendNotificationScreen());

      case RouteConfig.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());

      case RouteConfig.statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());

      case RouteConfig.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case RouteConfig.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case RouteConfig.resetPassword:
        final String userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(userId: userId),
        );

      //   revisar
      case RouteConfig.soundSettings:
        return MaterialPageRoute(builder: (_) => const SoundSettingsScreen(userId: '',));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}