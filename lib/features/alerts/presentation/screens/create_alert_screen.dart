import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/alert_repository.dart';
import '../../data/models/alert_type_model.dart';

class CreateAlertScreen extends StatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final _alertRepo = AlertRepository();
  final _msgController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<AlertTypeModel> _alertTypes = [];
  bool _loadingTypes = true;
  AlertTypeModel? _selectedType;
  final List<File> _selectedPhotos = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    try {
      final types = await _alertRepo.getAlertTypes();
      setState(() {
        _alertTypes = types;
        _loadingTypes = false;
      });
    } catch (e) {
      setState(() => _loadingTypes = false);
      _showError('Error al cargar tipos de alerta');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_selectedPhotos.length >= 5) {
      _showError('Máximo 5 fotos');
      return;
    }
    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (picked.isNotEmpty) {
      final remaining = 5 - _selectedPhotos.length;
      final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
      setState(() => _selectedPhotos.addAll(toAdd));
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 5) {
      _showError('Máximo 5 fotos');
      return;
    }
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedPhotos.add(File(picked.path)));
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      _showError('Seleccione un tipo de alerta');
      return;
    }

    setState(() => _isSending = true);
    try {
      final employeeId = await AppConfig.getEmployeeId();
      final vehicleId = await AppConfig.getSelectedVehicleId();

      if (employeeId == null) {
        _showError('Error: ID de empleado no encontrado');
        return;
      }

      double? lat, lng;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {}

      await _alertRepo.sendAlert(
        idPersonal: employeeId,
        idTipoAlerta: _selectedType!.id,
        vehiculoId: vehicleId,
        latitud: lat,
        longitud: lng,
        mensaje: _msgController.text.trim(),
        fotos: _selectedPhotos.isNotEmpty ? _selectedPhotos : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta enviada correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error al enviar alerta');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primary;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar Alerta')),
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Tipo de Alerta ---
                  Text('Tipo de alerta',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _alertTypes.map((type) {
                      final isSelected = _selectedType?.id == type.id;
                      final color = _parseColor(type.colorHex);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : AppTheme.border,
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type.nombre,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- Mensaje ---
                  Text('Descripción (opcional)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _msgController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe brevemente el incidente...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Fotos ---
                  Row(
                    children: [
                      Text('Fotos',
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      Text('${_selectedPhotos.length}/5',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _photoButton(
                          Icons.photo_library_outlined, 'Galería',
                          onTap: _pickFromGallery),
                      const SizedBox(width: 8),
                      _photoButton(
                          Icons.camera_alt_outlined, 'Cámara',
                          onTap: _takePhoto),
                    ],
                  ),
                  if (_selectedPhotos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedPhotos.length,
                        itemBuilder: (ctx, i) {
                          return Container(
                            width: 88,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    _selectedPhotos[i],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // --- Submit ---
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSending ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ENVIAR ALERTA'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _photoButton(IconData icon, String label,
      {required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }
}
