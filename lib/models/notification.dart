class Notification {
  final String id;
  final String titulo;
  final String mensaje;
  final String? imagenUrl;
  final DateTime fechaCreacion;
  final List<String>? dispositivosObjetivo;
  bool leida;
  bool sonando;
  final bool enviada;
  final DateTime? fechaEnvio;

  Notification({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.imagenUrl,
    required this.fechaCreacion,
    this.dispositivosObjetivo,
    this.leida = false,
    this.sonando = false,
    this.enviada = false,
    this.fechaEnvio,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
        id: json['id'],
        titulo: json['titulo'],
        mensaje: json['mensaje'],
        imagenUrl: json['imagen_url'],
        fechaCreacion: DateTime.parse(json['fecha_creacion']),
    dispositivosObjetivo: json['dispositivos_objetivo'] != null
    ? List<String>.from(json['dispositivos_objetivo'])
        : null,
    leida: json['leida'] ?? false,
    sonando: json['sonando'] ?? false,
    enviada: json['enviada'] ?? false,
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'imagen_url': imagenUrl,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'dispositivos_objetivo': dispositivosObjetivo,
      'leida': leida,
      'sonando': sonando,
      'enviada': enviada,
      'fecha_envio': fechaEnvio?.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    String? imagenUrl,
    DateTime? fechaCreacion,
    List<String>? dispositivosObjetivo,
    bool? leida,
    bool? sonando,
    bool? enviada,
    DateTime? fechaEnvio,
  }) {
    return Notification(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      dispositivosObjetivo: dispositivosObjetivo ?? this.dispositivosObjetivo,
      leida: leida ?? this.leida,
      sonando: sonando ?? this.sonando,
      enviada: enviada ?? this.enviada,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
    );
  }
}