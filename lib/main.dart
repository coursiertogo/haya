import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'screens/splash_screen.dart';
import 'screens/send_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/demandes_screen.dart';
import 'services/managers.dart';
import 'services/haya_api_service.dart';

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
  static final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
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
    // Vérifier paiements reçus + rappels après que l'utilisateur soit chargé
    Future.delayed(const Duration(seconds: 4), () {
      _verifierNouveauxPaiements();
      _rappelerPaiementsEnAttente();
    });
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
      // Vérifier paiements reçus + rappels à chaque retour dans l'app
      _verifierNouveauxPaiements();
      _rappelerPaiementsEnAttente();
    }
  }

  Future<void> _verifierNouveauxPaiements() async {
    if (UserManager.id == 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tsMs = prefs.getInt('last_notif_check');
      final depuis = tsMs != null
          ? DateTime.fromMillisecondsSinceEpoch(tsMs)
          : DateTime.now();

      // Sauvegarder le timestamp avant la requête pour ne pas manquer de paiements
      await prefs.setInt('last_notif_check', DateTime.now().millisecondsSinceEpoch);

      if (tsMs == null) return; // Premier lancement : on sauvegarde sans notifier

      final demandes = await HayaApiService.getDemandes();
      for (final d in demandes) {
        if (d['statut'] != 'paye') continue;
        final payeLe = DateTime.tryParse(d['paye_le']?.toString() ?? '');
        if (payeLe == null || !payeLe.isAfter(depuis)) continue;
        final montant = int.tryParse(d['montant']?.toString() ?? '0') ?? 0;
        final objet = d['objet']?.toString() ?? 'Paiement';
        final montantFmt = montant.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: kOrange, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Paiement reçu !',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('$objet · FCFA $montantFmt',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
            backgroundColor: kNuit,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Voir',
              textColor: kOrange,
              onPressed: () => _navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const DemandesScreen()),
              ),
            ),
          ),
        );
      }
    } catch (_) {}
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
    final operateur = p['operateur']?.isNotEmpty == true ? p['operateur'] : null;
    final objet = p['objet']?.isNotEmpty == true ? p['objet'] : null;
    final ref = p['ref']?.isNotEmpty == true ? p['ref'] : null;
    // Sauvegarder pour rappel si le paiement n'est pas finalisé
    if (ref != null) _sauvegarderRefEnAttente(ref, numero, montant, operateur, objet);
    _navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => SendScreen(
        numeroInitial: numero,
        montantInitial: montant,
        operateurInitial: operateur,
        objetInitial: objet,
        refInitial: ref,
      ),
    ));
  }

  Future<void> _sauvegarderRefEnAttente(String ref, String numero, int? montant, String? operateur, String? objet) async {
    final prefs = await SharedPreferences.getInstance();
    final liste = prefs.getStringList('pending_to_pay') ?? [];
    if (!liste.contains(ref)) {
      liste.add(ref);
      await prefs.setStringList('pending_to_pay', liste);
    }
    await prefs.setString('pending_detail_$ref',
        '$numero|${montant ?? 0}|${operateur ?? ''}|${objet ?? ''}');
  }

  Future<void> _rappelerPaiementsEnAttente() async {
    final prefs = await SharedPreferences.getInstance();
    final liste = prefs.getStringList('pending_to_pay') ?? [];
    if (liste.isEmpty) return;
    final aRetirer = <String>[];
    for (final ref in liste) {
      final statut = await HayaApiService.getStatutDemande(ref);
      if (statut != 'en_attente') {
        aRetirer.add(ref);
        continue;
      }
      final detail = prefs.getString('pending_detail_$ref') ?? '|||';
      final parts = detail.split('|');
      final numero = parts[0];
      final montant = int.tryParse(parts[1]);
      final operateur = parts[2].isNotEmpty ? parts[2] : null;
      final objet = parts[3].isNotEmpty ? parts[3] : null;

      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.notifications_outlined, color: kOrange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Paiement en attente',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  if (objet != null)
                    Text(objet, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ]),
          backgroundColor: kNuit,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Payer',
            textColor: kOrange,
            onPressed: () => _navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => SendScreen(
                numeroInitial: numero,
                montantInitial: montant,
                operateurInitial: operateur,
                objetInitial: objet,
                refInitial: ref,
              ),
            )),
          ),
        ),
      );
    }
    if (aRetirer.isNotEmpty) {
      liste.removeWhere(aRetirer.contains);
      for (final ref in aRetirer) {
        prefs.remove('pending_detail_$ref');
      }
      await prefs.setStringList('pending_to_pay', liste);
    }
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
        scaffoldMessengerKey: _scaffoldKey,
        title: 'haya',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          cardColor: const Color(0xFFFFFFFF),
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF97316),
              primary: const Color(0xFF0D0D2B),
              surface: const Color(0xFFFFFFFF),
              brightness: Brightness.light),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF080818),
          cardColor: const Color(0xFF141430),
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF97316),
              brightness: Brightness.dark,
              primary: const Color(0xFFF97316),
              surface: const Color(0xFF141430)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
