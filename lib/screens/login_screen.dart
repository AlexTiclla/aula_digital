// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'register_screen.dart';  // Crearemos esta pantalla después

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
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // En lib/screens/login_screen.dart, modificar la función _login()
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      // Verificar el rol del usuario
      final userRole = userData['rol'];
      
      // Si es estudiante pero seleccionó profesor o viceversa
      if ((_isStudent && userRole != 'estudiante') || 
          (!_isStudent && userRole != 'profesor')) {
        setState(() {
          _errorMessage = 'Tipo de usuario incorrecto. Por favor selecciona el rol correcto.';
          _isLoading = false;
        });
        return;
      }
      
      // Navegar al dashboard correspondiente
      if (userRole == 'estudiante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(),  // Sin pasar ID
          ),
        );
      } else if (userRole == 'profesor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDashboard(),  // Sin pasar ID
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(),
      ),
    );
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
              // Logo o título (sin cambios)
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

              // Selector de tipo de usuario (sin cambios)
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
                          )
                        ],
                        selected: {_isStudent},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isStudent = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Formulario de inicio de sesión (sin cambios)
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
                            
                            // Botón de registro (solo para estudiantes)
                            if (_isStudent) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _goToRegister,
                                child: const Text('¿No tienes cuenta? Regístrate'),
                              ),
                            ],
                          ],
                        ),
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