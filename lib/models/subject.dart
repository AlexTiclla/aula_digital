class Subject {
  final int id;
  final String nombre;
  final String descripcion;
  final String areaConocimiento;
  final int horasSemanales;
  final String profesorFullName;
  final String horario;
  final String aula;
  final String modalidad;
  
  Subject({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.areaConocimiento,
    required this.horasSemanales,
    required this.profesorFullName,
    required this.horario,
    required this.aula,
    required this.modalidad,
  });
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'] ?? '',
      areaConocimiento: json['areaConocimiento'] ?? '',
      horasSemanales: json['horasSemanales'] ?? 0,
      profesorFullName: json['profesorFullName'] ?? 'Sin profesor asignado',
      horario: json['horario'] ?? 'Sin horario',
      aula: json['aula'] ?? 'Sin aula',
      modalidad: json['modalidad'] ?? 'Presencial',
    );
  }
} 