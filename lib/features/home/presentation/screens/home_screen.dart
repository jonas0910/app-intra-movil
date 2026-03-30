import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../vehicles/data/models/vehicle_model.dart';
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

  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  bool _loadingVehicles = true;

  String? _lastLocationTime;
  Timer? _serviceCheckTimer;

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
    final vehicleId = await AppConfig.getSelectedVehicleId();

    setState(() {
      _isTracking = isRunning;
      _employeeName = name;
      _employeeCode = code;
      _departmentName = dept;
    });

    try {
      final vehicleRepo = VehicleRepository();
      final vehicles = await vehicleRepo.getVehicles();
      VehicleModel? selected;
      if (vehicleId != null) {
        selected = vehicles.where((v) => v.id == vehicleId).firstOrNull;
      }
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle = selected;
        _loadingVehicles = false;
      });
    } catch (e) {
      setState(() => _loadingVehicles = false);
    }
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

  Future<void> _selectVehicle() async {
    final result = await showModalBottomSheet<VehicleModel?>(
      context: context,
      backgroundColor: AppTheme.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) => _VehicleSelectorSheet(
        vehicles: _vehicles,
        selected: _selectedVehicle,
      ),
    );

    if (result != null) {
      await AppConfig.setSelectedVehicle(
        id: result.id,
        placa: result.placa,
        tipo: result.tipo,
      );
      setState(() => _selectedVehicle = result);
    }
  }

  Future<void> _clearVehicle() async {
    await AppConfig.clearSelectedVehicle();
    setState(() => _selectedVehicle = null);
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
          title: const Text('Panel Principal'),
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
                'MÓDULOS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                      color: AppTheme.textMuted,
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
              title: 'Mis Alertas',
              subtitle: 'Historial y seguimiento de alertas enviadas',
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
              Text('Vehículo',
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
          const SizedBox(height: 10),
          if (_selectedVehicle != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getVehicleIcon(_selectedVehicle!.tipo),
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVehicle!.placa,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.primary),
                        ),
                        Text(
                          '${_selectedVehicle!.marca} ${_selectedVehicle!.modelo}'
                              .trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                    onPressed: _clearVehicle,
                    tooltip: 'Desvincular',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadingVehicles || _vehicles.isEmpty
                    ? null
                    : _selectVehicle,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  _vehicles.isEmpty && !_loadingVehicles
                      ? 'Sin vehículos disponibles'
                      : 'Seleccionar vehículo (opcional)',
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
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: AppTheme.textMuted),
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

// --- Vehicle Selector Bottom Sheet ---
class _VehicleSelectorSheet extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? selected;

  const _VehicleSelectorSheet({required this.vehicles, this.selected});

  IconData _getIcon(String tipo) {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Seleccionar Vehículo',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Unidad vehicular para el rastreo',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          ...vehicles.map((v) {
            final isSelected = selected?.id == v.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => Navigator.pop(context, v),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _getIcon(v.tipo),
                          size: 20,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.placa,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : null,
                                    ),
                              ),
                              Text(
                                '${v.tipo.toUpperCase()} · ${v.marca} ${v.modelo}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: AppTheme.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No hay vehículos disponibles',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
