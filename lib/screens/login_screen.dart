import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isStudent = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulación de inicio de sesión
    await Future.delayed(const Duration(seconds: 1));

    final dataService = DataService();
    await dataService.initialize();

    try {
      if (_isStudent) {
        final students = dataService.getStudents();
        final student = students.firstWhere(
          (s) => s.email.toLowerCase() == _emailController.text.toLowerCase(),
          orElse: () => throw Exception('Estudiante no encontrado'),
        );

        // En una aplicación real, verificaríamos la contraseña aquí
        // Por ahora, simplemente redirigimos al dashboard del estudiante
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(studentId: student.id),
          ),
        );
      } else {
        final teachers = dataService.getTeachers();
        final teacher = teachers.firstWhere(
          (t) => t.email.toLowerCase() == _emailController.text.toLowerCase(),
          orElse: () => throw Exception('Profesor no encontrado'),
        );

        // En una aplicación real, verificaríamos la contraseña aquí
        // Por ahora, simplemente redirigimos al dashboard del profesor
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDashboard(teacherId: teacher.id),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Usuario no encontrado o contraseña incorrecta';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo o título
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Aula Digital',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestión de Notas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),

              // Selector de tipo de usuario
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Selector de tipo de usuario
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Estudiante'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Profesor'),
                            icon: Icon(Icons.school),
                          ),
                        ],
                        selected: {_isStudent},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isStudent = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Formulario de inicio de sesión
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo electrónico';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Iniciar Sesión'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Información de ayuda
                      const Text(
                        'Usuarios de prueba:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Estudiante: carlos.rodriguez@universidad.edu\nProfesor: juan.perez@universidad.edu',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cualquier contraseña funcionará para esta demostración',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
