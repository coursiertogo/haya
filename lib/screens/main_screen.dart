import 'package:flutter/material.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'demandes_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onGoToProfile: () => changerOnglet(3)),
      const DemandesScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
  }

  void changerOnglet(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kOrange,
        unselectedItemColor: isDark ? Colors.white38 : Colors.grey,
        backgroundColor: isDark ? kCardDark : Colors.white,
        currentIndex: _currentIndex,
        selectedIconTheme:
            const IconThemeData(color: kOrange, size: 26),
        unselectedIconTheme: IconThemeData(
            color: isDark ? Colors.white38 : Colors.grey, size: 22),
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.request_page_outlined), label: 'Demandes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Activité'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
