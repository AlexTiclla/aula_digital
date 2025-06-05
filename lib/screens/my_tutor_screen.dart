import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyTutorScreen extends StatefulWidget {
  const MyTutorScreen({Key? key}) : super(key: key);

  @override
  _MyTutorScreenState createState() => _MyTutorScreenState();
}

class _MyTutorScreenState extends State<MyTutorScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Tutor? _tutor;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTutor();
  }

  Future<void> _loadTutor() async {
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
      
      print('Cargando tutor para estudiante ID: $estudianteId');

      final tutor = await _apiService.getTutorEstudiante(estudianteId);
      
      setState(() {
        _tutor = tutor;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar tutor: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Tutor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              onPressed: _loadTutor,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_tutor == null) {
      return const Center(
        child: Text(
          'No tienes un tutor asignado',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTutor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: TutorCard(tutor: _tutor!),
      ),
    );
  }
}

class TutorCard extends StatelessWidget {
  final Tutor tutor;

  const TutorCard({Key? key, required this.tutor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
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
                  radius: 40,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    tutor.nombre.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 30,
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
                        tutor.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tutor.relacionEstudiante,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildInfoSection('Información de contacto', [
              _buildInfoRow(Icons.phone, tutor.telefono),
              if (tutor.correo != null && tutor.correo!.isNotEmpty)
                _buildInfoRow(Icons.email, tutor.correo!),
            ]),
            const SizedBox(height: 16),
            if (tutor.ocupacion != null || tutor.lugarTrabajo != null)
              _buildInfoSection('Información laboral', [
                if (tutor.ocupacion != null && tutor.ocupacion!.isNotEmpty)
                  _buildInfoRow(Icons.work, tutor.ocupacion!),
                if (tutor.lugarTrabajo != null && tutor.lugarTrabajo!.isNotEmpty)
                  _buildInfoRow(Icons.business, tutor.lugarTrabajo!),
              ]),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showContactOptions(context);
                },
                icon: const Icon(Icons.message),
                label: const Text('Contactar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 203, 212, 226),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contactar a tutor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.indigo),
                title: const Text('Llamar'),
                subtitle: Text(tutor.telefono),
                onTap: () async {
                  // Cerrar el diálogo
                  Navigator.of(context).pop();
                  
                  // Lanzar la aplicación de teléfono
                  final Uri phoneUri = Uri(scheme: 'tel', path: tutor.telefono);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir la aplicación de teléfono'),
                        ),
                      );
                    }
                  }
                },
              ),
              if (tutor.correo != null && tutor.correo!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.indigo),
                  title: const Text('Enviar correo'),
                  subtitle: Text(tutor.correo!),
                  onTap: () async {
                    // Cerrar el diálogo
                    Navigator.of(context).pop();
                    
                    // Lanzar la aplicación de correo
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: tutor.correo,
                      queryParameters: {
                        'subject': 'Contacto desde Aula Digital'
                      }
                    );
                    
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo abrir la aplicación de correo'),
                          ),
                        );
                      }
                    }
                  },
                ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.content_copy, color: Colors.indigo),
                title: const Text('Copiar número de teléfono'),
                onTap: () {
                  // Cerrar el diálogo
                  Navigator.of(context).pop();
                  
                  // Copiar al portapapeles
                  Clipboard.setData(ClipboardData(text: tutor.telefono));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Número copiado al portapapeles'),
                    ),
                  );
                },
              ),
              if (tutor.correo != null && tutor.correo!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.content_copy, color: Colors.indigo),
                  title: const Text('Copiar correo electrónico'),
                  onTap: () {
                    // Cerrar el diálogo
                    Navigator.of(context).pop();
                    
                    // Copiar al portapapeles
                    Clipboard.setData(ClipboardData(text: tutor.correo!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Correo copiado al portapapeles'),
                      ),
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
} 