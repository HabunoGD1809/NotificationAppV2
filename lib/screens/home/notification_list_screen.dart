import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notifications/notification_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/theme_config.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.loadNotifications(refresh: true);
    await provider.loadUnreadNotifications();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMoreNotifications) {
        provider.loadNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Sin leer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(allNotifications: true),
          _buildNotificationList(allNotifications: false),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required bool allNotifications}) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final notifications = allNotifications
            ? provider.notifications
            : provider.unreadNotifications;

        if (provider.isLoading && notifications.isEmpty) {
          return const Center(child: LoadingIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadNotifications,
          child: notifications.isEmpty
              ? Center(
                  child: Text(
                    allNotifications
                        ? 'No hay notificaciones'
                        : 'No hay notificaciones sin leer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount:
                      notifications.length + (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= notifications.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: LoadingIndicator()),
                      );
                    }

                    return NotificationCard(
                      notification: notifications[index],
                      onMarkAsRead: () async {
                        await provider.markAsRead(notifications[index].id);
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
