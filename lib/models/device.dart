class Device {
  final String id;
  final String deviceId;
  final String deviceName;
  final String? modelo;
  final String? sistemaOperativo;
  bool estaOnline;
  final DateTime ultimoAcceso;
  String? sessionId;

  Device({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    this.modelo,
    this.sistemaOperativo,
    required this.estaOnline,
    required this.ultimoAcceso,
    this.sessionId,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      modelo: json['modelo'],
      sistemaOperativo: json['sistema_operativo'],
      estaOnline: json['esta_online'],
      ultimoAcceso: DateTime.parse(json['ultimo_acceso']),
      sessionId: json['session_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'modelo': modelo,
      'sistema_operativo': sistemaOperativo,
      'esta_online': estaOnline,
      'ultimo_acceso': ultimoAcceso.toIso8601String(),
      'session_id': sessionId,
    };
  }

  Device copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    String? modelo,
    String? sistemaOperativo,
    bool? estaOnline,
    DateTime? ultimoAcceso,
    String? sessionId,
  }) {
    return Device(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      modelo: modelo ?? this.modelo,
      sistemaOperativo: sistemaOperativo ?? this.sistemaOperativo,
      estaOnline: estaOnline ?? this.estaOnline,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}