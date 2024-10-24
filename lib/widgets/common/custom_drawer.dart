import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/theme_config.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 24,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            accountName: Text(user?.nombre ?? 'Usuario'),
            accountEmail: Text(user?.email ?? ''),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Inicio'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notificaciones'),
                  trailing: notificationProvider.unreadNotifications.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notificationProvider.unreadNotifications.length
                                .toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                if (user?.esAdmin == true) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Administración',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Panel de Control'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/dashboard');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.send_outlined),
                    title: const Text('Enviar Notificación'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/send-notification');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Gestión de Usuarios'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/users');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: const Text('Estadísticas'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/statistics');
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Perfil'),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Configuración de Sonido'),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings/sound');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cerrar Sesión'),
                        content: const Text(
                            '¿Estás seguro de que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                            ),
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
// Footer con información de la versión
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
