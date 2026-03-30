import '../../../core/network/dio_client.dart';
import 'models/vehicle_model.dart';

class VehicleRepository {
  /// Fetch available vehicles for security department
  Future<List<VehicleModel>> getVehicles() async {
    final dio = await DioClient.getInstance();
    final response =
        await dio.get('/api/seguridad-ciudadana/vehiculos');

    final data = response.data;
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((json) => VehicleModel.fromJson(json))
          .toList();
    }
    return [];
  }
}
