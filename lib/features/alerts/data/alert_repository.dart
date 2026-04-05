import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'models/alert_model.dart';
import 'models/alert_type_model.dart';

class AlertRepository {
  /// Get available alert types
  Future<List<AlertTypeModel>> getAlertTypes() async {
    final dio = await DioClient.getInstance();
    final response =
        await dio.get('/api/seguridad-ciudadana/tipos-alerta');

    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((json) => AlertTypeModel.fromJson(json))
          .toList();
    }
    if (data is List) {
      return data
          .map((json) => AlertTypeModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Send a new alert with optional photos
  Future<void> sendAlert({
    required int idPersonal,
    required int idTipoAlerta,
    int? vehiculoId,
    double? latitud,
    double? longitud,
    String? mensaje,
    List<File>? fotos,
  }) async {
    final dio = await DioClient.getInstance();

    final formData = FormData.fromMap({
      'id_personal': idPersonal,
      'id_tipo_alerta': idTipoAlerta,
      if (vehiculoId != null) 'id_vehiculo': vehiculoId,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (mensaje != null && mensaje.isNotEmpty) 'mensaje': mensaje,
    });

    // Add photo files
    if (fotos != null) {
      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        formData.files.add(MapEntry(
          'fotos[]',
          await MultipartFile.fromFile(
            file.path,
            filename: 'foto_${i + 1}.jpg',
          ),
        ));
      }
    }

    await dio.post(
      '/api/seguridad-ciudadana/alertas',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// Get alert history for a specific employee
  Future<List<AlertModel>> getAlertHistory(int idPersonal,
      {int page = 1, int perPage = 20}) async {
    final dio = await DioClient.getInstance();
    final response = await dio.get(
      '/api/seguridad-ciudadana/alertas/personal/$idPersonal',
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((json) => AlertModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Get detailed info for a single alert
  Future<AlertModel> getAlertDetail(int alertId) async {
    final dio = await DioClient.getInstance();
    final response =
        await dio.get('/api/seguridad-ciudadana/alertas/$alertId');

    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return AlertModel.fromJson(data['data']);
    }
    return AlertModel.fromJson(data);
  }
}
