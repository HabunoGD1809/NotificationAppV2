class Statistics {
  final int totalNotificaciones;
  final int notificacionesEnviadas;
  final int notificacionesLeidas;
  final int dispositivosActivos;
  final Map<String, dynamic>? estadisticasAdicionales;

  Statistics({
    required this.totalNotificaciones,
    required this.notificacionesEnviadas,
    required this.notificacionesLeidas,
    required this.dispositivosActivos,
    this.estadisticasAdicionales,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalNotificaciones: json['total_notificaciones'],
      notificacionesEnviadas: json['notificaciones_enviadas'],
      notificacionesLeidas: json['notificaciones_leidas'],
      dispositivosActivos: json['dispositivos_activos'],
      estadisticasAdicionales: json['estadisticas_adicionales'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_notificaciones': totalNotificaciones,
      'notificaciones_enviadas': notificacionesEnviadas,
      'notificaciones_leidas': notificacionesLeidas,
      'dispositivos_activos': dispositivosActivos,
      'estadisticas_adicionales': estadisticasAdicionales,
    };
  }

  Statistics copyWith({
    int? totalNotificaciones,
    int? notificacionesEnviadas,
    int? notificacionesLeidas,
    int? dispositivosActivos,
    Map<String, dynamic>? estadisticasAdicionales,
  }) {
    return Statistics(
      totalNotificaciones: totalNotificaciones ?? this.totalNotificaciones,
      notificacionesEnviadas: notificacionesEnviadas ?? this.notificacionesEnviadas,
      notificacionesLeidas: notificacionesLeidas ?? this.notificacionesLeidas,
      dispositivosActivos: dispositivosActivos ?? this.dispositivosActivos,
      estadisticasAdicionales: estadisticasAdicionales ?? this.estadisticasAdicionales,
    );
  }
}