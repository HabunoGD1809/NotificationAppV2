import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_drawer.dart';
import '../../widgets/notifications/notification_list_item.dart';
import '../../config/theme_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final notificationProvider =
      Provider.of<NotificationProvider>(context, listen: false);
      if (!notificationProvider.isLoading) {
        notificationProvider.loadNotifications();
      }
    }
  }

  Future<void> _initializeScreen() async {
    final notificationProvider =
    Provider.of<NotificationProvider>(context, listen: false);
    final deviceProvider =
    Provider.of<DeviceProvider>(context, listen: false);

    await Future.wait([
      notificationProvider.loadNotifications(refresh: true),
      deviceProvider.initializeCurrentDevice(),
    ]);
  }

  Future<void> _handleRefresh() async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .loadNotifications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inicio',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Banner de bienvenida
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      authProvider.currentUser?.nombre.substring(0, 1) ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido, ${authProvider.currentUser?.nombre ?? "Usuario"}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${notificationProvider.unreadNotifications.length} notificaciones sin leer',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de notificaciones
            Expanded(
              child: notificationProvider.isLoading &&
                  notificationProvider.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: notificationProvider.notifications.length +
                    (notificationProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= notificationProvider.notifications.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final notification =
                  notificationProvider.notifications[index];
                  return NotificationListItem(
                    notification: notification,
                    onTap: () async {
                      if (!notification.leida) {
                        await notificationProvider
                            .markAsRead(notification.id);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: authProvider.currentUser?.esAdmin == true
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/send-notification');
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}