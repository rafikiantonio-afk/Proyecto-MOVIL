import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

// INICIO DE SESION

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              children: [
                const Spacer(flex: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo fondo azul.jpg',
                    width: 240,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Artículos Perdidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión con tu cuenta de Google para continuar',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 3),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  SignInButton(
                    Buttons.google,
                    text: 'Iniciar sesión con Google',
                    onPressed: _handleGoogleSignIn,
                  ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}