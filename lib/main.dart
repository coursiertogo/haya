import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'constants.dart';
import 'screens/splash_screen.dart';
import 'screens/send_screen.dart';

void main() {
  runApp(const HayaApp());
}

class HayaApp extends StatefulWidget {
  const HayaApp({super.key});
  @override
  State<HayaApp> createState() => _HayaAppState();
}

class _HayaAppState extends State<HayaApp> {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<Uri> _linkSub;

  @override
  void initState() {
    super.initState();
    ThemeManager.instance.addListener(() => setState(() {}));
    _initDeepLinks();
  }

  void _initDeepLinks() {
    final appLinks = AppLinks();
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
    _linkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'haya' || uri.host != 'send') return;
    final p = uri.queryParameters;
    final numero = p['numero'] ?? '';
    final montant = int.tryParse(p['montant'] ?? '');
    final operateur =
        p['operateur']?.isNotEmpty == true ? p['operateur'] : null;
    final objet = p['objet']?.isNotEmpty == true ? p['objet'] : null;
    _navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => SendScreen(
        numeroInitial: numero,
        montantInitial: montant,
        operateurInitial: operateur,
        objetInitial: objet,
      ),
    ));
  }

  @override
  void dispose() {
    _linkSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDark;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'haya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF97316),
            primary: const Color(0xFF0D0D2B)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF97316),
            brightness: Brightness.dark,
            primary: const Color(0xFFF97316)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
