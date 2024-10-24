import 'package:flutter/material.dart';
import '../../models/notification.dart' as model;
import '../../config/theme_config.dart';
import 'package:intl/intl.dart';

class NotificationListItem extends StatelessWidget {
  final model.Notification notification;
  final VoidCallback? onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.leida ? 1 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: notification.leida
              ? Colors.grey[200]
              : AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            notification.leida
                ? Icons.notifications_outlined
                : Icons.notifications_active,
            color: notification.leida
                ? Colors.grey
                : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          notification.titulo,
          style: TextStyle(
            fontWeight:
            notification.leida ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.mensaje,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(notification.fechaCreacion),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: !notification.leida
            ? Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
          ),
        )
            : null,
        isThreeLine: true,
      ),
    );
  }
}