import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/taux_change_service.dart';
import '../services/managers.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  Future<void> _initialiser() async {
    TauxChangeService.chargerTaux();
    await PinManager.charger();
    await NumerosManager.charger();
    await UserManager.charger();
    await ContactsManager.charger();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    _initialiser().then((_) => Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (UserManager.id != 0 && PinManager.pinDefini) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LockScreen(onDeverrouille: () {}),
            ),
          );
        } else if (UserManager.id != 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    }));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNuit,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  color: kOrange, borderRadius: BorderRadius.circular(24)),
              child:
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fade,
            child: Column(children: [
              const Text('haya',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -2)),
              const SizedBox(height: 8),
              Text("Envoie. C'est parti.",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 60),
          FadeTransition(
            opacity: _fade,
            child: Text('Togo',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}
