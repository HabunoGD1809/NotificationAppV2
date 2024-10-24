class User {
  final String id;
  final String nombre;
  final String email;
  final bool esAdmin;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.esAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      esAdmin: json['es_admin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'es_admin': esAdmin,
    };
  }

  User copyWith({
    String? id,
    String? nombre,
    String? email,
    bool? esAdmin,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      esAdmin: esAdmin ?? this.esAdmin,
    );
  }
}