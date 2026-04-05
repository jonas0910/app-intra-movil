import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/alert_repository.dart';
import '../../data/models/alert_model.dart';

class AlertDetailScreen extends StatefulWidget {
  final int alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _alertRepo = AlertRepository();
  AlertModel? _alert;
  bool _isLoading = true;
  bool _hasError = false;
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      _serverUrl = await AppConfig.getServerUrl();
      final alert = await _alertRepo.getAlertDetail(widget.alertId);
      setState(() {
        _alert = alert;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading alert detail: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resuelta':
        return AppTheme.success;
      case 'rechazada':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'resuelta':
        return 'RESUELTA';
      case 'rechazada':
        return 'RECHAZADA';
      default:
        return 'PENDIENTE';
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resuelta':
        return Icons.check_circle_outline;
      case 'rechazada':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Alerta')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError || _alert == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('Error al cargar detalle',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadDetail,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final alert = _alert!;
    final color = _statusColor(alert.estado);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Status Header ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(alert.estado), color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(alert.estado),
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (alert.tipoAlertaNombre != null)
                        Text(
                          alert.tipoAlertaNombre!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Location Map ---
          if (alert.latitud != null && alert.longitud != null) ...[
            Text('Ubicación del reporte',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              height: 200,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(alert.latitud!, alert.longitud!),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_seguridad_ciudadana',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(alert.latitud!, alert.longitud!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // --- General Information ---
          _section('Información General', [
            _infoRow('ID Alerta', '#${alert.id}'),
            _infoRow('Fecha de Envío', _formatDate(alert.createdAt)),
            if (alert.resueltaAt != null)
              _infoRow('Fecha de Resolución', _formatDate(alert.resueltaAt)),
            if (alert.latitud != null && alert.longitud != null)
              _infoRow(
                'Coordenadas',
                '${alert.latitud!.toStringAsFixed(6)}, ${alert.longitud!.toStringAsFixed(6)}',
              ),
          ]),
          const SizedBox(height: 12),

          // --- Description ---
          if (alert.mensaje != null && alert.mensaje!.isNotEmpty) ...[
            _section('Descripción del incidente', [], customContent: Text(
              alert.mensaje!,
              style: Theme.of(context).textTheme.bodyLarge,
            )),
            const SizedBox(height: 12),
          ],

          // --- Control Center Observations ---
          if (alert.observaciones != null &&
              alert.observaciones!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message_outlined,
                          size: 16, color: AppTheme.success),
                      const SizedBox(width: 8),
                      Text(
                        'Observaciones del Centro de Control',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppTheme.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.observaciones!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // --- Photos Evidence ---
          if (alert.fotos.isNotEmpty) ...[
            Text('Evidencia fotográfica (${alert.fotos.length})',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            ...alert.fotos.map((url) {
              final fullUrl =
                  url.startsWith('http') ? url : '$_serverUrl$url';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    alignment: Alignment.center,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 200,
                        color: AppTheme.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, stack) {
                      debugPrint('Error loading image at $fullUrl: $err');
                      return Container(
                        height: 150,
                        color: AppTheme.surface,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  size: 40, color: AppTheme.textMuted),
                              const SizedBox(height: 8),
                              Text('No se pudo cargar la imagen',
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows,
      {Widget? customContent}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...rows,
          ],
          if (customContent != null) ...[
            const SizedBox(height: 10),
            customContent,
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
