import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/background_service.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'providers/device_provider.dart';
import 'providers/websocket_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios
  await NotificationService().initialize();
  await BackgroundService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
      ],
      child: const NotificationApp(),
    ),
  );
}
