import 'package:flutter/material.dart';
import '../../models/notification.dart' as model;
import '../../config/theme_config.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final model.Notification notification;
  final VoidCallback? onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.leida ? 1 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: !notification.leida ? onMarkAsRead : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(12),
              color: notification.leida
                  ? null
                  : AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    notification.leida
                        ? Icons.notifications_outlined
                        : Icons.notifications_active,
                    color: notification.leida
                        ? Colors.grey
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.titulo,
                          style: TextStyle(
                            fontWeight: notification.leida
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(notification.fechaCreacion),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.leida)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.mensaje,
                    style: TextStyle(
                      color: Colors.grey[800],
                    ),
                  ),
                  if (notification.imagenUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        notification.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Footer con acciones
            if (!notification.leida)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onMarkAsRead,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Marcar como leída'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}