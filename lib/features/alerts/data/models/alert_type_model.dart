/// Modelo de tipo de alerta
class AlertTypeModel {
  final int id;
  final String nombre;
  final String? colorHex;

  AlertTypeModel({
    required this.id,
    required this.nombre,
    this.colorHex,
  });

  factory AlertTypeModel.fromJson(Map<String, dynamic> json) {
    return AlertTypeModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? json['descripcion'] ?? 'Desconocido',
      colorHex: json['color_hex'],
    );
  }
}
