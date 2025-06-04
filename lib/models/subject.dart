class Subject {
  final int id;
  final int materiaId;
  final String nombre;
  final String descripcion;
  final String areaConocimiento;
  final int horasSemanales;
  final int profesorId;
  final String profesorNombre;
  final String profesorApellido;
  final String horario;
  final String aula;
  final String modalidad;
  final bool isActive;
  
  Subject({
    required this.id,
    required this.materiaId,
    required this.nombre,
    required this.descripcion,
    required this.areaConocimiento,
    required this.horasSemanales,
    required this.profesorId,
    required this.profesorNombre,
    required this.profesorApellido,
    required this.horario,
    required this.aula,
    required this.modalidad,
    this.isActive = true,
  });
  
  // Nombre completo del profesor
  String get profesorFullName => '$profesorNombre $profesorApellido';
  
  // Factory para crear desde un mapa (útil para JSON)
  factory Subject.fromJson(Map<String, dynamic> json) {
    final materia = json['materia'] ?? {};
    final profesor = json['profesor'] ?? {};
    
    return Subject(
      id: json['id'],
      materiaId: materia['id'] ?? 0,
      nombre: materia['nombre'] ?? 'Sin nombre',
      descripcion: materia['descripcion'] ?? '',
      areaConocimiento: materia['area_conocimiento'] ?? '',
      horasSemanales: materia['horas_semanales'] ?? 0,
      profesorId: profesor['id'] ?? 0,
      profesorNombre: profesor['nombre'] ?? '',
      profesorApellido: profesor['apellido'] ?? '',
      horario: json['horario'] ?? 'Sin horario',
      aula: json['aula'] ?? 'Sin aula',
      modalidad: json['modalidad'] ?? 'Presencial',
    );
  }
} 