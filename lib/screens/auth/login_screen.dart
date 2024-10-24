import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../utils/validators.dart';
import '../../config/theme_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      developer.log('Formulario inválido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('Iniciando proceso de login');
      developer.log('Email: ${_emailController.text}');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      developer.log('Resultado del login: $success');

      if (!mounted) return;

      if (success) {
        developer.log('Login exitoso, inicializando WebSocket');
        wsProvider.initialize();

        if (!mounted) return;

        developer.log('Navegando a home');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        developer.log('Error en login: ${authProvider.error}');
        _showErrorDialog(authProvider.error ?? 'Error desconocido en el inicio de sesión');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error inesperado en login',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showErrorDialog('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de inicio de sesión'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo y título
                  Image.asset(
                    'assets/images/logo.png',
                    height: MediaQuery.of(context).size.height * 0.15,
                    errorBuilder: (context, error, stackTrace) {
                      developer.log('Error cargando logo', error: error, stackTrace: stackTrace);
                      return const Icon(Icons.error_outline, size: 64);
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bienvenido',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.validateEmail,
                    enabled: !_isLoading,
                    onChanged: (value) => developer.log('Email cambiado: $value'),
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                    enabled: !_isLoading,
                    onChanged: (_) => developer.log('Contraseña modificada'),
                  ),
                  const SizedBox(height: 16),

                  // Recordarme
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Recordarme'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const LoadingIndicator()
                        : const Text('Iniciar sesión'),
                  ),

                  if (Provider.of<AuthProvider>(context).error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        Provider.of<AuthProvider>(context).error!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}