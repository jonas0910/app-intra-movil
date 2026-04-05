import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../vehicles/data/models/assigned_vehicle_model.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import '../../../alerts/presentation/screens/create_alert_screen.dart';
import '../../../alerts/presentation/screens/alert_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTracking = false;
  String _employeeName = '';
  String _employeeCode = '';
  String _departmentName = '';

  List<AssignedVehicleModel> _assignedVehicles = [];
  AssignedVehicleModel? _selectedAssignedVehicle;
  bool _loadingVehicles = true;

  String? _lastLocationTime;
  Timer? _serviceCheckTimer;
  String? _entityName;
  String? _entityLogo;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenForServiceEvents();
    _startServicePolling();
  }

  /// Polls every 3s to detect stop from notification
  void _startServicePolling() {
    _serviceCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {
        final isRunning = await BackgroundLocationService.isRunning;
        if (mounted && _isTracking != isRunning) {
          setState(() {
            _isTracking = isRunning;
            if (!isRunning) _lastLocationTime = null;
          });
        }
      },
    );
  }

  void _listenForServiceEvents() {
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map && data['event'] == 'location_sent' && mounted) {
        setState(() {
          _lastLocationTime = TimeOfDay.now().format(context);
        });
      }
    });
  }

  Future<void> _loadData() async {
    final isRunning = await BackgroundLocationService.isRunning;
    final name = await AppConfig.getEmployeeName();
    final code = await AppConfig.getEmployeeCode();
    final dept = await AppConfig.getDepartmentName();
    final entName = await AppConfig.getEntityName();
    final entLogo = await AppConfig.getEntityLogo();

    setState(() {
      _isTracking = isRunning;
      _employeeName = name;
      _employeeCode = code;
      _departmentName = dept;
      _entityName = entName;
      _entityLogo = entLogo;
    });

    try {
      final vehicleRepo = VehicleRepository();
      final assignedVehicles = await vehicleRepo.getAssignedVehicles();
      final selectedId = await AppConfig.getSelectedVehicleId();

      setState(() {
        _assignedVehicles = assignedVehicles;
        _loadingVehicles = false;
        
        if (assignedVehicles.isNotEmpty) {
          // Find previously selected vehicle in the new list
          final found = assignedVehicles.where((v) => v.idVehiculo == selectedId);
          if (found.isNotEmpty) {
            _selectedAssignedVehicle = found.first;
          } else {
            // Auto-select first only if nothing was stored OR it no longer exists
             _selectedAssignedVehicle = assignedVehicles.first;
             _onSelectVehicle(_selectedAssignedVehicle!);
          }
        } else {
          _selectedAssignedVehicle = null;
          AppConfig.clearSelectedVehicle();
        }
      });
    } catch (e) {
      setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _onSelectVehicle(AssignedVehicleModel vehicle) async {
    await AppConfig.setSelectedVehicle(
      id: vehicle.idVehiculo,
      placa: vehicle.vehiculo.placa,
      tipo: vehicle.vehiculo.tipo,
    );
    setState(() => _selectedAssignedVehicle = vehicle);
    
    // If tracking is active, the task handler reads from prefs every interval, so it's fine.
  }

  Future<void> _onDeselectVehicle() async {
    await AppConfig.clearSelectedVehicle();
    setState(() => _selectedAssignedVehicle = null);
  }

  Future<void> _toggleTracking(bool enable) async {
    if (enable) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Servicios de ubicación deshabilitados', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Permisos de ubicación denegados', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Permisos denegados permanentemente', isError: true);
        return;
      }

      final started = await BackgroundLocationService.startService();
      setState(() => _isTracking = started);
    } else {
      await BackgroundLocationService.stopService();
      setState(() {
        _isTracking = false;
        _lastLocationTime = null;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('Se detendrá el rastreo y cerrará la sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BackgroundLocationService.stopService();
      await AppConfig.clearSession();
      await AppConfig.clearSelectedVehicle();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (_entityLogo != null && _entityLogo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.network(
                      _entityLogo!,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.security,
                              size: 20, color: AppTheme.primary),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _entityName ?? 'CENTRO DE CONTROL MUNICIPAL',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: _logout,
              tooltip: 'Cerrar Sesión',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // --- Employee Card ---
            _buildEmployeeCard(),
            const SizedBox(height: 14),

            // --- Tracking ---
            _buildTrackingCard(),
            const SizedBox(height: 14),

            // --- Vehicle ---
            _buildVehicleCard(),
            const SizedBox(height: 20),

            // --- Section Title ---
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'MÓDULOS OPERATIVOS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
              ),
            ),

            // --- Quick Actions ---
            _buildModuleCard(
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.danger,
              title: 'Enviar Alerta',
              subtitle: 'Reportar una incidencia o emergencia',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateAlertScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildModuleCard(
              icon: Icons.history_rounded,
              iconColor: AppTheme.primary,
              title: 'Mis Alertas e Intervenciones',
              subtitle: 'Bitácora de incidencias reportadas en servicio',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AlertHistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _employeeName.isNotEmpty
                    ? _employeeName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_employeeCode.isNotEmpty || _departmentName.isNotEmpty)
                  Text(
                    [_employeeCode, _departmentName]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isTracking
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.border,
          width: _isTracking ? 1 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _isTracking
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isTracking ? Icons.gps_fixed : Icons.gps_off_outlined,
                  color:
                      _isTracking ? AppTheme.success : AppTheme.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTracking ? 'Rastreo activo' : 'Rastreo inactivo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _isTracking
                                ? AppTheme.success
                                : AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      _isTracking
                          ? 'Enviando ubicación cada 30s'
                          : 'Tu ubicación no se está enviando',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isTracking,
                onChanged: _toggleTracking,
              ),
            ],
          ),
          if (_lastLocationTime != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time,
                      size: 12, color: AppTheme.success),
                  const SizedBox(width: 4),
                  Text(
                    'Último envío: $_lastLocationTime',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.success,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_outlined,
                  size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('Asignación de Unidad',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (_loadingVehicles)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_assignedVehicles.isNotEmpty) ...[
            ..._assignedVehicles.map((assigned) {
              final isSelected =
                  _selectedAssignedVehicle?.idVehiculo == assigned.idVehiculo;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.05)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getVehicleIcon(assigned.vehiculo.tipo),
                        size: 20,
                        color:
                            isSelected ? AppTheme.primary : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assigned.vehiculo.placa,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : null,
                                  ),
                            ),
                            Text(
                              '${assigned.vehiculo.marca} ${assigned.vehiculo.modelo}'
                                  .trim(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.route_outlined,
                                    size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${assigned.ruta.nombre} · ${assigned.ruta.sector}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      isSelected
                          ? OutlinedButton(
                              onPressed: _onDeselectVehicle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.danger,
                                side: BorderSide(
                                    color:
                                        AppTheme.danger.withValues(alpha: 0.5)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Quitar',
                                  style: TextStyle(fontSize: 12)),
                            )
                          : FilledButton(
                              onPressed: () => _onSelectVehicle(assigned),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Poner',
                                  style: TextStyle(fontSize: 12)),
                            ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (_selectedAssignedVehicle == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Text(
                    'Ningún vehículo seleccionado (Rastreo Personal)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.danger,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _loadingVehicles
                      ? 'Cargando asignación...'
                      : 'Sin vehículo asignado para hoy',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.backgroundCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'motocicleta':
        return Icons.two_wheeler;
      case 'bicicleta':
        return Icons.pedal_bike;
      case 'patrullero':
        return Icons.local_police;
      default:
        return Icons.directions_car;
    }
  }

  @override
  void dispose() {
    _serviceCheckTimer?.cancel();
    super.dispose();
  }
}
