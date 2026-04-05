import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../../home/presentation/screens/home_screen.dart';
import 'screens/server_config_screen.dart';

/// Pantalla de login con botón sutil para configuración de servidor.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _obscurePass = true;
  int _configTapCount = 0;

  String? _entityName;
  String? _entityLogo;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final name = await AppConfig.getEntityName();
    final logo = await AppConfig.getEntityLogo();
    if (mounted) {
      setState(() {
        _entityName = name;
        _entityLogo = logo;
      });
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passController.text;
    if (email.isEmpty || pass.isEmpty) {
      _showError('Complete todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepo.login(email, pass);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('Credenciales inválidas o servidor no disponible');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  /// 5 taps en el ícono abre configuración de servidor
  void _onConfigTap() {
    _configTapCount++;
    if (_configTapCount >= 5) {
      _configTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // --- Logo & Entity Branding ---
                GestureDetector(
                  onTap: _onConfigTap,
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _entityLogo != null && _entityLogo!.isNotEmpty
                            ? Image.network(
                                _entityLogo!,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.security_rounded,
                                  size: 40,
                                  color: AppTheme.primary,
                                ),
                              )
                            : const Icon(
                                Icons.security_rounded,
                                size: 40,
                                color: AppTheme.primary,
                              ),
                      ),
                      const SizedBox(height: 20),
                      if (_entityName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _entityName!.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SISTEMA DE SEGURIDAD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                ),
                const SizedBox(height: 48),

                // --- Welcome Message ---
                Text(
                  'ACCESO INSTITUCIONAL',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'SISTEMA INTEGRAL DE SEGURIDAD CIUDADANA',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 40),

                // --- Form ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller: _passController,
                        obscureText: _obscurePass,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon:
                              const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Login button
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ingresar'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
                // Botón sutil - long press abre config
                GestureDetector(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ServerConfigScreen()),
                    );
                  },
                  child: Text(
                    'v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
