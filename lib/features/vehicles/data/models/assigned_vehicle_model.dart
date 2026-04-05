import 'vehicle_model.dart';

/// Modelo que representa una asignación de vehículo en una ruta de patrullaje
class AssignedVehicleModel {
  final int id;
  final int idVehiculo;
  final VehicleModel vehiculo;
  final AssignedRouteModel ruta;

  AssignedVehicleModel({
    required this.id,
    required this.idVehiculo,
    required this.vehiculo,
    required this.ruta,
  });

  factory AssignedVehicleModel.fromJson(Map<String, dynamic> json) {
    return AssignedVehicleModel(
      id: json['id'] ?? 0,
      idVehiculo: json['id_vehiculo'] ?? 0,
      vehiculo: VehicleModel.fromJson(json['vehiculo'] ?? {}),
      ruta: AssignedRouteModel.fromJson(json['ruta'] ?? {}),
    );
  }
}

/// Modelo que representa la ruta asignada
class AssignedRouteModel {
  final String nombre;
  final String sector;

  AssignedRouteModel({
    required this.nombre,
    required this.sector,
  });

  factory AssignedRouteModel.fromJson(Map<String, dynamic> json) {
    return AssignedRouteModel(
      nombre: json['nombre'] ?? '',
      sector: json['sector'] is Map ? (json['sector']['nombre_sector'] ?? '') : '',
    );
  }
}
