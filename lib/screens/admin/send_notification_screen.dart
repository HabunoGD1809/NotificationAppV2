import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../models/device.dart';
import '../../config/theme_config.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _sendToAll = true;
  final Set<String> _selectedDevices = {};

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    await Provider.of<DeviceProvider>(context, listen: false).loadDevices();
  }

  Future<void> _handleSendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final notificationProvider =
    Provider.of<NotificationProvider>(context, listen: false);

    final success = await notificationProvider.sendNotification(
      _titleController.text,
      _messageController.text,
      _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      _sendToAll ? null : _selectedDevices.toList(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación enviada exitosamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notificationProvider.error ?? 'Error al enviar notificación'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Notificación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un mensaje';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen (opcional)',
                  prefixIcon: Icon(Icons.image),
                ),
              ), // Cerramos el SizedBox aquí
              const SizedBox(height: 24),

              // Selector de destinatarios
              const Text(
                'Destinatarios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enviar a todos los dispositivos'),
                value: _sendToAll,
                onChanged: (value) {
                  setState(() {
                    _sendToAll = value;
                    if (value) {
                      _selectedDevices.clear();
                    }
                  });
                },
              ),
              if (!_sendToAll)
                ...[
                  const SizedBox(height: 16),
                  Consumer<DeviceProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: LoadingIndicator());
                      }

                      if (provider.devices.isEmpty) {
                        return const Center(
                          child: Text('No hay dispositivos disponibles'),
                        );
                      }

                      return Card(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.devices.length,
                          itemBuilder: (context, index) {
                            final Device device = provider.devices[index];
                            return CheckboxListTile(
                              title: Text(device.deviceName),
                              subtitle: Text(device.modelo ?? 'Dispositivo desconocido'),
                              secondary: Icon(
                                Icons.smartphone,
                                color: device.estaOnline
                                    ? AppTheme.onlineColor
                                    : AppTheme.offlineColor,
                              ),
                              value: _selectedDevices.contains(device.id),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedDevices.add(device.id);
                                  } else {
                                    _selectedDevices.remove(device.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              const SizedBox(height: 24),
              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _handleSendNotification,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const LoadingIndicator()
                          : const Text('Enviar Notificación'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
