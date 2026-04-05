import '../../../core/network/dio_client.dart';
import 'models/assigned_vehicle_model.dart';
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

  /// Get today's assigned vehicle based on authenticated user
  Future<List<AssignedVehicleModel>> getAssignedVehicles() async {
    final dio = await DioClient.getInstance();
    final response = await dio
        .get('/api/seguridad-ciudadana/rutas-patrullaje/mi-vehiculo-asignado');

    final data = response.data;
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((json) => AssignedVehicleModel.fromJson(json))
          .toList();
    }
    return [];
  }
}
