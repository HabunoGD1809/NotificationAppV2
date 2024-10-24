import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/notification_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/admin/statistics_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/theme_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final notificationProvider =
    Provider.of<NotificationProvider>(context, listen: false);

    await Future.wait([
      deviceProvider.loadDevices(),
      notificationProvider.loadNotifications(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticsSection(),
              const SizedBox(height: 24),
              _buildDeviceSection(),
              const SizedBox(height: 24),
              _buildNotificationChart(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/admin/send-notification'),
        icon: const Icon(Icons.notification_add),
        label: const Text('Nueva Notificación'),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            StatisticsCard(
              title: 'Notificaciones Totales',
              value: provider.notifications.length.toString(),
              icon: Icons.notifications,
              color: AppTheme.primaryColor,
            ),
            StatisticsCard(
              title: 'Sin Leer',
              value: provider.unreadNotifications.length.toString(),
              icon: Icons.mark_email_unread,
              color: AppTheme.warningColor,
            ),
            StatisticsCard(
              title: 'Dispositivos',
              value: context.watch<DeviceProvider>().devices.length.toString(),
              icon: Icons.devices,
              color: AppTheme.secondaryColor,
            ),
            StatisticsCard(
              title: 'Dispositivos Online',
              value: context
                  .watch<DeviceProvider>()
                  .devices
                  .where((d) => d.estaOnline)
                  .length
                  .toString(),
              icon: Icons.online_prediction,
              color: AppTheme.successColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceSection() {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Dispositivos Activos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.devices.length,
                itemBuilder: (context, index) {
                  final device = provider.devices[index];
                  return ListTile(
                    leading: Icon(
                      Icons.smartphone,
                      color: device.estaOnline
                          ? AppTheme.onlineColor
                          : AppTheme.offlineColor,
                    ),
                    title: Text(device.deviceName),
                    subtitle: Text(device.modelo ?? 'Dispositivo desconocido'),
                    trailing: Text(
                      device.estaOnline ? 'En línea' : 'Desconectado',
                      style: TextStyle(
                        color: device.estaOnline
                            ? AppTheme.onlineColor
                            : AppTheme.offlineColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationChart() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final data = _createTimeSeriesData(provider);

        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        final spots = data.map((point) {
          return FlSpot(
            point.time.millisecondsSinceEpoch.toDouble(),
            point.notifications.toDouble(),
          );
        }).toList();

        return SizedBox(
          height: 300,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notificaciones por Día',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                              interval: 86400000, // 1 día en milisegundos
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.black12),
                        ),
                        minX: spots.first.x,
                        maxX: spots.last.x,
                        minY: 0,
                        maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<TimeSeriesNotifications> _createTimeSeriesData(
      NotificationProvider provider) {
    final Map<DateTime, int> notificationsByDay = {};

    for (var notification in provider.notifications) {
      final date = DateTime(
        notification.fechaCreacion.year,
        notification.fechaCreacion.month,
        notification.fechaCreacion.day,
      );

      notificationsByDay[date] = (notificationsByDay[date] ?? 0) + 1;
    }

    return notificationsByDay.entries
        .map((entry) => TimeSeriesNotifications(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }
}

class TimeSeriesNotifications {
  final DateTime time;
  final int notifications;

  TimeSeriesNotifications(this.time, this.notifications);
}