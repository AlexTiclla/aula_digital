import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MyTeachersScreen extends StatefulWidget {
  const MyTeachersScreen({Key? key}) : super(key: key);

  @override
  _MyTeachersScreenState createState() => _MyTeachersScreenState();
}

class _MyTeachersScreenState extends State<MyTeachersScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Profesor> _profesores = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfesores();
  }

  Future<void> _loadProfesores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtener el ID de estudiante
      final estudianteId = await _authService.getEstudianteId();
      
      if (estudianteId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró ID de estudiante';
        });
        return;
      }
      
      print('Cargando profesores para estudiante ID: $estudianteId');

      final profesores = await _apiService.getProfesoresEstudiante(estudianteId);
      
      setState(() {
        _profesores = profesores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar profesores: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Profesores'),
        backgroundColor: Colors.indigo,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfesores,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_profesores.isEmpty) {
      return const Center(
        child: Text(
          'No tienes profesores asignados en este periodo',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfesores,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _profesores.length,
        itemBuilder: (context, index) {
          final profesor = _profesores[index];
          return ProfesorCard(profesor: profesor);
        },
      ),
    );
  }
}

class ProfesorCard extends StatelessWidget {
  final Profesor profesor;

  const ProfesorCard({Key? key, required this.profesor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    profesor.nombre.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profesor.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profesor.especialidad != null && profesor.especialidad!.isNotEmpty)
                        Text(
                          profesor.especialidad!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (profesor.email.isNotEmpty)
              _buildInfoRow(Icons.email, profesor.email),
            if (profesor.telefono != null && profesor.telefono!.isNotEmpty)
              _buildInfoRow(Icons.phone, profesor.telefono!),
            if (profesor.nivelAcademico != null && profesor.nivelAcademico!.isNotEmpty)
              _buildInfoRow(Icons.school, profesor.nivelAcademico!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 