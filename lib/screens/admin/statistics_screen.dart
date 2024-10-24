import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/notification_provider.dart';
import '../../providers/device_provider.dart';
import '../../models/statistics.dart';
import '../../config/theme_config.dart';
import '../../widgets/common/loading_indicator.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Statistics? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notificationProvider =
      Provider.of<NotificationProvider>(context, listen: false);
      _statistics = await notificationProvider.getStatistics();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildDeliveryRateChart(),
              const SizedBox(height: 24),
              _buildDeviceStatusChart(),
              const SizedBox(height: 24),
              _buildNotificationHistoryChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Notificaciones',
          _statistics?.totalNotificaciones.toString() ?? '0',
          Icons.notifications,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Notificaciones Leídas',
          _statistics?.notificacionesLeidas.toString() ?? '0',
          Icons.done_all,
          AppTheme.successColor,
        ),
        _buildStatCard(
          'Tasa de Entrega',
          '${((_statistics?.notificacionesEnviadas ?? 0) / (_statistics?.totalNotificaciones ?? 1) * 100).toStringAsFixed(1)}%',
          Icons.send,
          AppTheme.secondaryColor,
        ),
        _buildStatCard(
          'Dispositivos Activos',
          _statistics?.dispositivosActivos.toString() ?? '0',
          Icons.devices,
          AppTheme.accentColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryRateChart() {
    final sent = _statistics?.notificacionesEnviadas ?? 0;
    final total = _statistics?.totalNotificaciones ?? 0;
    final pending = total - sent;

    return _buildChartCard(
      'Tasa de Entrega',
      AspectRatio(
        aspectRatio: 1.5,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: sent.toDouble(),
                title: 'Enviadas\n$sent',
                color: AppTheme.successColor,
                radius: 100,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              PieChartSectionData(
                value: pending.toDouble(),
                title: 'Pendientes\n$pending',
                color: AppTheme.warningColor,
                radius: 100,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatusChart() {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final onlineDevices = deviceProvider.devices.where((device) => device.estaOnline).length;
    final offlineDevices = deviceProvider.devices.length - onlineDevices;

    return _buildChartCard(
      'Estado de Dispositivos',
      AspectRatio(
        aspectRatio: 1.5,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: onlineDevices.toDouble(),
                title: 'En línea\n$onlineDevices',
                color: AppTheme.onlineColor,
                radius: 100,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              PieChartSectionData(
                value: offlineDevices.toDouble(),
                title: 'Desconectados\n$offlineDevices',
                color: AppTheme.offlineColor,
                radius: 100,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryChart() {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    // Agrupar notificaciones por día
    final Map<DateTime, int> dailyNotifications = {};
    for (var notification in notifications) {
      final date = DateTime(
        notification.fechaCreacion.year,
        notification.fechaCreacion.month,
        notification.fechaCreacion.day,
      );
      dailyNotifications[date] = (dailyNotifications[date] ?? 0) + 1;
    }

    final sortedData = dailyNotifications.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedData.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = sortedData.map((e) {
      return FlSpot(
        e.key.millisecondsSinceEpoch.toDouble(),
        e.value.toDouble(),
      );
    }).toList();

    return _buildChartCard(
      'Historial de Notificaciones',
      AspectRatio(
        aspectRatio: 1.5,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
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
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}