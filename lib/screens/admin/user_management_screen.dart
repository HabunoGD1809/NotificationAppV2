import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../models/user.dart';
import '../../config/theme_config.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await Provider.of<UserProvider>(context, listen: false).loadUsers();
  }

  Future<void> _showResetPasswordDialog(User user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restablecer contraseña de ${user.nombre}'),
        content: const Text(
            '¿Estás seguro de que deseas restablecer la contraseña de este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/reset-password',
                arguments: user.id,
              );
            },
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteUserDialog(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar usuario ${user.nombre}'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este usuario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.deleteUser(user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Usuario eliminado exitosamente'
                : userProvider.error ?? 'Error al eliminar usuario',
          ),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showCreateUserDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear nuevo usuario'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un correo electrónico';
                  }
                  if (!value.contains('@')) {
                    return 'Por favor ingrese un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                final success = await userProvider.createUser(
                  _nameController.text,
                  _emailController.text,
                  _passwordController.text,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Usuario creado exitosamente'
                          : userProvider.error ?? 'Error al crear usuario',
                    ),
                    backgroundColor:
                        success ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (provider.users.isEmpty) {
            return const Center(
              child: Text('No hay usuarios registrados'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.users.length,
              itemBuilder: (context, index) {
                final user = provider.users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        user.nombre.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.nombre),
                    subtitle: Text(user.email),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'reset',
                          child: Text('Restablecer contraseña'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar usuario'),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'reset':
                            _showResetPasswordDialog(user);
                            break;
                          case 'delete':
                            _showDeleteUserDialog(user);
                            break;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
