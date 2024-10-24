import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class DialogHelper {
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static void showSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<T?> showLoadingDialog<T>({
    required BuildContext context,
    required Future<T> future,
    String message = 'Cargando...',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );

    try {
      final result = await future;
      if (context.mounted) {
        Navigator.pop(context); // Cierra el diálogo de carga
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cierra el diálogo de carga
        showErrorDialog(
          context: context,
          title: 'Error',
          message: e.toString(),
        );
      }
      return null;
    }
  }
}