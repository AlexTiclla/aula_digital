class Profesor {
  final int id;
  final int usuarioId;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String? carnetIdentidad;
  final String? especialidad;
  final String? nivelAcademico;

  Profesor({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    this.carnetIdentidad,
    this.especialidad,
    this.nivelAcademico,
  });

  // Nombre completo del profesor
  String get nombreCompleto => '$nombre $apellido';

  factory Profesor.fromJson(Map<String, dynamic> json) {
    return Profesor(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'],
      carnetIdentidad: json['carnet_identidad'],
      especialidad: json['especialidad'],
      nivelAcademico: json['nivel_academico'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'carnet_identidad': carnetIdentidad,
      'especialidad': especialidad,
      'nivel_academico': nivelAcademico,
    };
  }
} 