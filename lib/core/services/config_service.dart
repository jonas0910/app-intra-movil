import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';

/// Service to handle application-wide configuration from the API.
class ConfigService {
  ConfigService._();

  /// Fetches institutional information (logo, name) and saves it to local storage.
  /// This endpoint is public and doesn't require authentication.
  static Future<void> fetchAndSavePublicConfig() async {
    try {
      final dio = await DioClient.getInstance();
      final response = await dio.get('/api/seguridad-ciudadana/config/public-info');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await AppConfig.setEntityInfo(
          name: data['name'] ?? 'Seguridad Ciudadana',
          logoUrl: data['logo_url'] ?? '',
          phone: data['phone'],
        );
        debugPrint('Configuración institucional cargada: ${data['name']}');
      }
    } catch (e) {
      // Sliently fail - the app will use cached values or defaults
      debugPrint('Error al cargar la configuración pública: $e');
    }
  }
}
