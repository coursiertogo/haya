import 'package:flutter/material.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'mes_demandes_screen.dart';
import 'payment_request_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MesDemandesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kNuit,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Accueil
                _NavItem(
                  onTap: () => setState(() => _currentIndex = 0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.home_outlined,
                        size: 24,
                        color: _currentIndex == 0
                            ? kOrange
                            : Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(height: 4),
                    Text('Accueil',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _currentIndex == 0
                                ? kOrange
                                : Colors.white.withValues(alpha: 0.5))),
                  ]),
                ),

                // Haya — bouton action central
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentRequestScreen())),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                          color: kOrange,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: kOrange.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: const Center(
                        child: Text('⬆',
                            style: TextStyle(fontSize: 20, color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Haya',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kOrange)),
                  ]),
                ),

                // Demandes
                _NavItem(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 24,
                        color: _currentIndex == 1
                            ? kOrange
                            : Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(height: 4),
                    Text('Demandes',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _currentIndex == 1
                                ? kOrange
                                : Colors.white.withValues(alpha: 0.5))),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _NavItem({required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      );
}
