import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/services/background_location_service.dart';
import 'core/services/config_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.backgroundDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await BackgroundLocationService.initializeService();

  runApp(const IntraApp());
}

class IntraApp extends StatelessWidget {
  const IntraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

/// Splash screen con verificación de autenticación
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  String? _entityName;
  String? _entityLogo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _loadCachedBranding();
    _initializeApp();
  }

  Future<void> _loadCachedBranding() async {
    final name = await AppConfig.getEntityName();
    final logo = await AppConfig.getEntityLogo();
    if (mounted) {
      setState(() {
        _entityName = name;
        _entityLogo = logo;
      });
    }
  }

  Future<void> _initializeApp() async {
    // 1. Fetch organizational info (logo, name) publically.
    await ConfigService.fetchAndSavePublicConfig();
    
    // Refresh branding if it changed
    await _loadCachedBranding();

    // 2. Auth check
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final token = await AppConfig.getToken();
    final employeeId = await AppConfig.getEmployeeId();

    if (!mounted) return;

    Widget destination;
    if (token != null && employeeId != null) {
      await DioClient.recreateInstance();
      if (!mounted) return;
      destination = const HomeScreen();
    } else {
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient / Atmosphere
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Container
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _entityLogo != null && _entityLogo!.isNotEmpty
                        ? Image.network(
                            _entityLogo!,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.security_rounded,
                              size: 40,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(
                            Icons.security_rounded,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App Name or Entity Name
                  Text(
                    _entityName?.toUpperCase() ?? 'SEGURIDAD CIUDADANA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PLATAFORMA DE SEGURIDAD',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.0,
                        ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Professional Loader
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Text(
                  'GESTIÓN E INNOVACIÓN MUNICIPAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted.withValues(alpha: 0.6),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
