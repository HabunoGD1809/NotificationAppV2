import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../config/theme_config.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback? onResetPassword;
  final VoidCallback? onDelete;
  final bool showAdminOptions;

  const UserListItem({
    super.key,
    required this.user,
    this.onResetPassword,
    this.onDelete,
    this.showAdminOptions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            user.nombre.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                user.esAdmin ? 'Administrador' : 'Usuario',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              backgroundColor: user.esAdmin
                  ? AppTheme.primaryColor
                  : AppTheme.secondaryColor,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: showAdminOptions
            ? PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.lock_reset),
                  SizedBox(width: 8),
                  Text('Restablecer contraseña'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text(
                    'Eliminar usuario',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'reset':
                onResetPassword?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
        )
            : null,
        isThreeLine: true,
      ),
    );
  }
}