import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'constants.dart';
import 'screens/splash_screen.dart';
import 'screens/send_screen.dart';
import 'screens/lock_screen.dart';
import 'services/managers.dart';

void main() {
  runApp(const HayaApp());
}

class HayaApp extends StatefulWidget {
  const HayaApp({super.key});
  @override
  State<HayaApp> createState() => _HayaAppState();
}

class _HayaAppState extends State<HayaApp> with WidgetsBindingObserver {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<Uri> _linkSub;
  Timer? _inactiviteTimer;
  DateTime? _tempsPause;
  bool _estVerrouille = false;

  static const _delaiVerrouillage = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    ThemeManager.instance.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  bool get _verrouillagePossible =>
      UserManager.id != 0 && PinManager.pinDefini;

  void _resetTimer() {
    if (!_verrouillagePossible) return;
    _inactiviteTimer?.cancel();
    _inactiviteTimer = Timer(_delaiVerrouillage, _verrouillerApp);
  }

  void _verrouillerApp() {
    if (_estVerrouille || !_verrouillagePossible) return;
    _estVerrouille = true;
    _inactiviteTimer?.cancel();
    _navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => LockScreen(
        onDeverrouille: () {
          _estVerrouille = false;
          _resetTimer();
        },
      ),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _inactiviteTimer?.cancel();
      if (_verrouillagePossible) _tempsPause = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_verrouillagePossible && _tempsPause != null) {
        final absente = DateTime.now().difference(_tempsPause!);
        _tempsPause = null;
        if (absente >= _delaiVerrouillage) {
          _verrouillerApp();
        } else {
          _resetTimer();
        }
      }
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _inactiviteTimer?.cancel();
    _linkSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDark;
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      child: MaterialApp(
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
      ),
    );
  }
}
