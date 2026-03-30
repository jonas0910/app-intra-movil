/// Modelo de vehículo del módulo de Seguridad Ciudadana
class VehicleModel {
  final int id;
  final String placa;
  final String codigo;
  final String tipo;
  final String marca;
  final String modelo;

  VehicleModel({
    required this.id,
    required this.placa,
    required this.codigo,
    required this.tipo,
    required this.marca,
    required this.modelo,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      placa: json['placa'] ?? '',
      codigo: json['codigo'] ?? '',
      tipo: json['tipo'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
    );
  }

  /// Display name for the vehicle selector
  String get displayName => '$placa • ${marca.isNotEmpty ? marca : tipo}${modelo.isNotEmpty ? ' $modelo' : ''}';
}
