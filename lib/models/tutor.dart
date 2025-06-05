class Tutor {
  final int id;
  final String nombre;
  final String apellido;
  final String relacionEstudiante;
  final String telefono;
  final String? ocupacion;
  final String? lugarTrabajo;
  final String? correo;

  Tutor({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.relacionEstudiante,
    required this.telefono,
    this.ocupacion,
    this.lugarTrabajo,
    this.correo,
  });

  // Nombre completo del tutor
  String get nombreCompleto => '$nombre $apellido';

  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      relacionEstudiante: json['relacion_estudiante'] ?? '',
      telefono: json['telefono'] ?? '',
      ocupacion: json['ocupacion'],
      lugarTrabajo: json['lugar_trabajo'],
      correo: json['correo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'relacion_estudiante': relacionEstudiante,
      'telefono': telefono,
      'ocupacion': ocupacion,
      'lugar_trabajo': lugarTrabajo,
      'correo': correo,
    };
  }
} 