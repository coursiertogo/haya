import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

// Ancien écran de connexion — remplacé par OnboardingScreen
// Conservé uniquement pour compatibilité si une ancienne version navigue ici
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (r) => false,
      );
    });
    return const SizedBox.shrink();
  }
}
