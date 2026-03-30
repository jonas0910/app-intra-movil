/// Modelo de alerta del módulo de Seguridad Ciudadana
class AlertModel {
  final int id;
  final int idPersonal;
  final int? idTipoAlerta;
  final String? tipoAlertaNombre;
  final String? tipoAlertaColor;
  final int? vehiculoId;
  final double? latitud;
  final double? longitud;
  final String? mensaje;
  final String estado; // pendiente, resuelta, rechazada
  final String? observaciones;
  final List<String> fotos;
  final DateTime? createdAt;
  final DateTime? resueltaAt;

  AlertModel({
    required this.id,
    required this.idPersonal,
    this.idTipoAlerta,
    this.tipoAlertaNombre,
    this.tipoAlertaColor,
    this.vehiculoId,
    this.latitud,
    this.longitud,
    this.mensaje,
    required this.estado,
    this.observaciones,
    this.fotos = const [],
    this.createdAt,
    this.resueltaAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    // Parse photos list
    List<String> photoUrls = [];
    if (json['fotos'] is List) {
      photoUrls = (json['fotos'] as List).map((f) {
        if (f is String) return f;
        if (f is Map) return f['url']?.toString() ?? '';
        return '';
      }).where((url) => url.isNotEmpty).toList();
    }

    return AlertModel(
      id: json['id'] ?? 0,
      idPersonal: json['id_personal'] ?? 0,
      idTipoAlerta: json['id_tipo_alerta'],
      tipoAlertaNombre: json['tipo_alerta']?['nombre'] ??
          json['tipo_alerta']?['descripcion'],
      tipoAlertaColor: json['tipo_alerta']?['color_hex'],
      vehiculoId: json['vehiculo_id'],
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
      mensaje: json['mensaje'],
      estado: json['estado'] ?? 'pendiente',
      observaciones: json['observaciones'],
      fotos: photoUrls,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      resueltaAt: json['resuelta_at'] != null
          ? DateTime.tryParse(json['resuelta_at'].toString())
          : null,
    );
  }

  bool get isPendiente => estado.toLowerCase() == 'pendiente';
  bool get isResuelta => estado.toLowerCase() == 'resuelta';
  bool get isRechazada => estado.toLowerCase() == 'rechazada';
}
