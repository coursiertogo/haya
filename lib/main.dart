import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'paygate_service.dart';

void main() {
  runApp(const HayaApp());
}

// ─── THEME MANAGER ───────────────────────────────────────
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;
  ThemeManager._();

  bool _isDark = false;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class HayaApp extends StatefulWidget {
  const HayaApp({super.key});
  @override
  State<HayaApp> createState() => _HayaAppState();
}

class _HayaAppState extends State<HayaApp> {
  @override
  void initState() {
    super.initState();
    ThemeManager.instance.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDark;
    return MaterialApp(
      title: 'haya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF97316), primary: const Color(0xFF0D0D2B)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF97316), brightness: Brightness.dark, primary: const Color(0xFFF97316)),
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

// ─── COULEURS ADAPTATIVES ────────────────────────────────
const kNuit = Color(0xFF0D0D2B);
const kOrange = Color(0xFFF97316);
const kVert = Color(0xFF1D9E75);
const kFond = Color(0xFFF5F4FF);
const kFondDark = Color(0xFF121212);
const kRouge = Color(0xFFE24B4A);
const kCardDark = Color(0xFF1E1E1E);

Color kFondCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? kFondDark : kFond;
Color kCardCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? kCardDark : Colors.white;
Color kTextCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
Color kSubtextCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey;
Color kBorderCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200;
Color kInputCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

const avatarColors = [
  Color(0xFFEEEDFE), Color(0xFFD7F3EA), Color(0xFFFAEEDA),
  Color(0xFFFFE4E4), Color(0xFFE4F0FF), Color(0xFFF0E4FF),
];
const avatarTextColors = [
  Color(0xFF3C3489), Color(0xFF0F6E56), Color(0xFF854F0B),
  Color(0xFFA32D2D), Color(0xFF185FA5), Color(0xFF6B21A8),
];

const tmoneySuffixes = ['70', '71', '90', '91', '92', '93'];
const floozPrefixes = ['79', '94', '95', '96', '97', '98', '99'];

String detectOperateur(String numero) {
  final clean = numero.replaceAll(RegExp(r'\D'), '');
  if (clean.length < 2) return '';
  final prefix = clean.substring(0, 2);
  if (tmoneySuffixes.contains(prefix)) return 'tmoney';
  if (floozPrefixes.contains(prefix)) return 'flooz';
  return 'inconnu';
}

Future<void> partagerWhatsApp(String message) async {
  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> partagerSMS(String message) async {
  final url = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
}

// ─── TAUX DE CHANGE ──────────────────────────────────────
class TauxChangeService {
  static double _tauxEuroFcfa = 655.957;
  static bool _charge = false;
  static double get tauxEuroFcfa => _tauxEuroFcfa;

  static Future<void> chargerTaux() async {
    if (_charge) return;
    try {
      final r = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/EUR'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final taux = json.decode(r.body)['rates']['XOF'];
        if (taux != null) { _tauxEuroFcfa = (taux as num).toDouble(); _charge = true; }
      }
    } catch (_) {}
  }

  static String fcfaVersEuros(int fcfa) => (fcfa / _tauxEuroFcfa).toStringAsFixed(2);
}

// ─── PIN MANAGER ─────────────────────────────────────────
class PinManager {
  static String _pin = '1234';
  static bool _pinDefini = false;
  static bool get pinDefini => _pinDefini;
  static void definirPin(String pin) { _pin = pin; _pinDefini = true; }
  static bool verifierPin(String pin) => pin == _pin;
}

// ─── CONTACT ─────────────────────────────────────────────
class Contact {
  final String nom, numero, operateur;
  final int colorIndex;
  Contact({required this.nom, required this.numero, required this.operateur, required this.colorIndex});
}

class ContactsManager {
  static final List<Contact> contacts = [
    Contact(nom: 'Ama Kpodo', numero: '90123456', operateur: 'tmoney', colorIndex: 0),
    Contact(nom: 'Yawa Bossa', numero: '94567890', operateur: 'flooz', colorIndex: 1),
    Contact(nom: 'Kofi Dossou', numero: '91234567', operateur: 'tmoney', colorIndex: 4),
    Contact(nom: 'Edem Klu', numero: '97654321', operateur: 'flooz', colorIndex: 5),
  ];
}

// ─── SPLASH SCREEN ───────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    TauxChangeService.chargerTaux();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNuit,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ScaleTransition(scale: _scale,
          child: Container(width: 90, height: 90,
            decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 48))),
        const SizedBox(height: 20),
        FadeTransition(opacity: _fade, child: Column(children: [
          const Text('haya', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w600, letterSpacing: -2)),
          const SizedBox(height: 8),
          Text("Envoie. C'est parti.", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
        ])),
        const SizedBox(height: 60),
        FadeTransition(opacity: _fade,
          child: Text('Togo · Pays-Bas', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13))),
      ])),
    );
  }
}

// ─── ÉCRAN PIN ───────────────────────────────────────────
class PinScreen extends StatefulWidget {
  final String titre, sousTitre;
  final Function(String) onSuccess;
  final bool modeDefinition;
  const PinScreen({super.key, required this.titre, required this.sousTitre,
      required this.onSuccess, this.modeDefinition = false});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _pin = '', _pinConfirm = '';
  bool _confirming = false, _error = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void dispose() { _shakeCtrl.dispose(); super.dispose(); }

  void _onChiffre(String c) {
    if (_pin.length >= 4) return;
    setState(() { _pin += c; _error = false; });
    if (_pin.length == 4) _valider();
  }

  void _effacer() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _valider() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (widget.modeDefinition) {
      if (!_confirming) {
        setState(() { _pinConfirm = _pin; _pin = ''; _confirming = true; });
      } else {
        if (_pin == _pinConfirm) {
          PinManager.definirPin(_pin);
          widget.onSuccess(_pin);
        } else {
          setState(() { _pin = ''; _error = true; _confirming = false; _pinConfirm = ''; });
          _shakeCtrl.forward(from: 0);
        }
      }
    } else {
      if (PinManager.verifierPin(_pin)) {
        widget.onSuccess(_pin);
      } else {
        setState(() { _pin = ''; _error = true; });
        _shakeCtrl.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titre = widget.modeDefinition && _confirming ? 'Confirmer le PIN' : widget.titre;
    final sousTitre = widget.modeDefinition && _confirming ? 'Retape le meme PIN' : widget.sousTitre;
    return Scaffold(
      backgroundColor: kNuit,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: SafeArea(child: Column(children: [
        const SizedBox(height: 20),
        Container(width: 60, height: 60, decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 32)),
        const SizedBox(height: 24),
        Text(titre, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(sousTitre, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        AnimatedBuilder(animation: _shakeAnim, builder: (context, child) {
          final dx = _error ? ((_shakeAnim.value * 4).round() % 2 == 0 ? -8.0 : 8.0) * (1 - _shakeAnim.value) : 0.0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        }, child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 10), width: 16, height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: i < _pin.length ? kOrange : (_error ? kRouge : Colors.white.withOpacity(0.3))))))),
        if (_error) Padding(padding: const EdgeInsets.only(top: 16),
            child: const Text('PIN incorrect. Reessaie.', style: TextStyle(color: kRouge, fontSize: 13))),
        const Spacer(),
        Padding(padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          child: Column(children: [
            for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','\u232b']])
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row.map((c) =>
                GestureDetector(
                  onTap: c == '\u232b' ? _effacer : c.isEmpty ? null : () => _onChiffre(c),
                  child: Container(width: 72, height: 72, margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: c.isEmpty ? Colors.transparent : Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                    child: Center(child: c == '\u232b'
                        ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 22)
                        : Text(c, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300))))
                )).toList()),
          ])),
      ])),
    );
  }
}

// ─── DIALOG STATUT TRANSFERT ─────────────────────────────
class _TransfertProgressDialog extends StatefulWidget {
  final String numero, operateur;
  final int montant;
  const _TransfertProgressDialog({required this.numero, required this.operateur, required this.montant});
  @override
  State<_TransfertProgressDialog> createState() => _TransfertProgressDialogState();
}

class _TransfertProgressDialogState extends State<_TransfertProgressDialog> {
  int _etape = 0;
  final _etapes = ['Connexion securisee...', 'Verification du numero...', 'Traitement du paiement...', 'Confirmation en cours...'];

  @override
  void initState() { super.initState(); _progresser(); }

  void _progresser() async {
    for (int i = 0; i < _etapes.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _etape = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 60, height: 60,
            decoration: const BoxDecoration(color: Color(0xFFE7F0FF), shape: BoxShape.circle),
            child: const CircularProgressIndicator(color: kNuit, strokeWidth: 3)),
        const SizedBox(height: 20),
        Text('FCFA ${widget.montant}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kNuit)),
        const SizedBox(height: 4),
        Text('vers +228 ${widget.numero}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 24),
        ..._etapes.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 22, height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: e.key < _etape ? kVert : e.key == _etape ? kOrange : Colors.grey.shade200),
              child: Icon(e.key < _etape ? Icons.check : Icons.circle, color: Colors.white, size: 14)),
            const SizedBox(width: 12),
            Text(e.value, style: TextStyle(fontSize: 13,
                color: e.key < _etape ? kVert : e.key == _etape ? kNuit : Colors.grey,
                fontWeight: e.key == _etape ? FontWeight.w500 : FontWeight.normal)),
          ]))),
      ])));
  }
}

// ─── TX ITEM CLIQUABLE ───────────────────────────────────
class _TxItemClickable extends StatelessWidget {
  final String initiales, nom, operateur, date, montant, numero;
  final bool isOut;
  final int colorIndex;
  const _TxItemClickable({required this.initiales, required this.nom, required this.operateur,
      required this.date, required this.montant, required this.isOut, required this.numero, this.colorIndex = 0});

  @override
  Widget build(BuildContext context) {
    final isTmoney = operateur == 'Tmoney';
    final bgColor = avatarColors[colorIndex % avatarColors.length];
    final textColor = avatarTextColors[colorIndex % avatarTextColors.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context,
        backgroundColor: kCardCtx(context),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 28, backgroundColor: bgColor,
                child: Text(initiales, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
            const SizedBox(height: 12),
            Text(nom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kTextCtx(context))),
            const SizedBox(height: 4),
            Text('+228 $numero', style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SendScreen(numeroInitial: numero))); },
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text('Envoyer a nouveau a $nom', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(backgroundColor: kNuit, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ]))),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100))),
        child: Row(children: [
          CircleAvatar(radius: 22, backgroundColor: bgColor,
              child: Text(initiales, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTextCtx(context))),
            const SizedBox(height: 3),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: isTmoney ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(operateur, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500,
                    color: isTmoney ? kNuit : const Color(0xFF854F0B)))),
              const SizedBox(width: 6),
              Text(date, style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(montant, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isOut ? kRouge : kVert)),
            Icon(Icons.chevron_right, color: kSubtextCtx(context), size: 16),
          ]),
        ])),
    );
  }
}

// ─── ÉCRAN PRINCIPAL ─────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [HomeScreen(), SendScreen(), HistoryScreen(), ProfileScreen()];

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
        selectedIconTheme: const IconThemeData(color: kOrange, size: 26),
        unselectedIconTheme: IconThemeData(color: isDark ? Colors.white38 : Colors.grey, size: 22),
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.send_outlined), label: 'Envoyer'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activite'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

// ─── ACCUEIL ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: Column(children: [
        // Header gradient (toujours sombre)
        Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)])),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                const Text('haya', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
              ]),
              CircleAvatar(radius: 18, backgroundColor: kOrange.withOpacity(0.3),
                  child: const Text('KA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 18),
            const Text('Bonjour, Koffi !', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
              child: const Row(children: [
                Icon(Icons.lock_outline, color: Colors.white54, size: 18), SizedBox(width: 10),
                Text('Connectez votre compte pour voir votre solde', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
            const Text('Togo · Mode local', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _CompactAction(icon: Icons.arrow_outward, label: 'Envoyer',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendScreen()))),
                _VertDivider(),
                _CompactAction(icon: Icons.arrow_downward, label: 'Recevoir',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveScreen()))),
                _VertDivider(),
                _CompactAction(icon: Icons.request_page_outlined, label: 'Demander',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentRequestScreen()))),
                _VertDivider(),
                _CompactAction(icon: Icons.people_outline, label: 'Contacts',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())).then((_) => setState(() {}))),
              ])),
          ])),
        // Transactions récentes (sans la section contacts)
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Transactions recentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTextCtx(context))),
            GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 13, color: kOrange, fontWeight: FontWeight.w500))),
          ])),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: const [
          _TxItemClickable(initiales: 'AK', nom: 'Ama Kpodo', operateur: 'Tmoney', date: 'Auj. 10:24', montant: '-5 000', isOut: true, colorIndex: 0, numero: '90123456'),
          _TxItemClickable(initiales: 'YB', nom: 'Yawa Bossa', operateur: 'Flooz', date: 'Hier 14:05', montant: '+20 000', isOut: false, colorIndex: 1, numero: '94567890'),
          _TxItemClickable(initiales: 'KD', nom: 'Kofi Dossou', operateur: 'Tmoney', date: '5 avr.', montant: '-10 000', isOut: true, colorIndex: 4, numero: '91234567'),
          _TxItemClickable(initiales: 'EK', nom: 'Edem Klu', operateur: 'Flooz', date: '3 avr.', montant: '+50 000', isOut: false, colorIndex: 5, numero: '97654321'),
          _TxItemClickable(initiales: 'NA', nom: 'Nana Agbeko', operateur: 'Tmoney', date: '1 avr.', montant: '-7 500', isOut: true, colorIndex: 2, numero: '91112233'),
        ])),
      ]),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: Colors.white24);
}

class _CompactAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _CompactAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: kOrange, size: 22), const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]));
}

// ─── CONTACTS ────────────────────────────────────────────
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  void _ajouter() {
    final nomCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: kCardCtx(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setM) {
        final op = numCtrl.text.length >= 2 ? detectOperateur(numCtrl.text) : '';
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nouveau contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kTextCtx(context))),
            const SizedBox(height: 20),
            Text('Nom complet', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(12)),
              child: TextField(controller: nomCtrl,
                  style: TextStyle(fontSize: 15, color: kTextCtx(context)),
                  decoration: const InputDecoration(hintText: 'Ex: Ama Kpodo', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
            const SizedBox(height: 16),
            Text('Numero', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('+228', style: TextStyle(fontSize: 14, color: kSubtextCtx(context), fontWeight: FontWeight.w500))),
                Expanded(child: TextField(controller: numCtrl, keyboardType: TextInputType.phone, maxLength: 8,
                    style: TextStyle(fontSize: 15, color: kTextCtx(context)),
                    decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none, counterText: ''),
                    onChanged: (_) => setM(() {}))),
              ])),
            if (op == 'tmoney') Padding(padding: const EdgeInsets.only(top: 8), child: Text('Tmoney', style: TextStyle(color: kNuit, fontSize: 12))),
            if (op == 'flooz') Padding(padding: const EdgeInsets.only(top: 8), child: const Text('Flooz', style: TextStyle(color: Color(0xFF854F0B), fontSize: 12))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (nomCtrl.text.isNotEmpty && numCtrl.text.length == 8 && (op == 'tmoney' || op == 'flooz')) {
                    setState(() { ContactsManager.contacts.add(Contact(nom: nomCtrl.text, numero: numCtrl.text, operateur: op,
                        colorIndex: ContactsManager.contacts.length % avatarColors.length)); });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kNuit, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)))),
            const SizedBox(height: 20),
          ]));
      }));
  }

  void _supprimer(int i) => showDialog(context: context, builder: (context) => AlertDialog(
    backgroundColor: kCardCtx(context),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text('Supprimer ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTextCtx(context))),
    content: Text('Supprimer ${ContactsManager.contacts[i].nom} ?', style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
      TextButton(onPressed: () { setState(() => ContactsManager.contacts.removeAt(i)); Navigator.pop(context); },
          child: const Text('Supprimer', style: TextStyle(color: kRouge))),
    ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(backgroundColor: kNuit, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Contacts favoris', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [IconButton(icon: const Icon(Icons.person_add_outlined, color: Colors.white), onPressed: _ajouter)]),
      body: ContactsManager.contacts.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, color: Colors.grey.shade300, size: 64), const SizedBox(height: 16),
              const Text('Aucun contact favori', style: TextStyle(color: Colors.grey, fontSize: 16)), const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _ajouter, icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(backgroundColor: kNuit, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            ]))
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: ContactsManager.contacts.length,
              itemBuilder: (context, i) {
                final c = ContactsManager.contacts[i];
                final ini = c.nom.split(' ').map((e) => e[0]).take(2).join();
                final bg = avatarColors[c.colorIndex % avatarColors.length];
                final tc = avatarTextColors[c.colorIndex % avatarTextColors.length];
                return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderCtx(context))),
                  child: Row(children: [
                    CircleAvatar(radius: 24, backgroundColor: bg, child: Text(ini, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tc))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.nom, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTextCtx(context))),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: c.operateur == 'tmoney' ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(4)),
                          child: Text(c.operateur == 'tmoney' ? 'Tmoney' : 'Flooz', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: c.operateur == 'tmoney' ? kNuit : const Color(0xFF854F0B)))),
                        const SizedBox(width: 6),
                        Text('+228 ${c.numero}', style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
                      ]),
                    ])),
                    GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SendScreen(numeroInitial: c.numero))),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.send_outlined, color: kOrange, size: 20))),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () => _supprimer(i),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kRouge.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.delete_outline, color: kRouge, size: 20))),
                  ]));
              }),
      floatingActionButton: ContactsManager.contacts.isNotEmpty
          ? FloatingActionButton(onPressed: _ajouter, backgroundColor: kOrange, child: const Icon(Icons.person_add_outlined, color: Colors.white)) : null,
    );
  }
}

// ─── RECEVOIR ────────────────────────────────────────────
class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String _op = 'tmoney';
  String get _num => _op == 'tmoney' ? '90123456' : '94123456';
  String get _nomOp => _op == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';
  String _msg() => 'Envoie-moi de l\'argent sur Haya !\n\nNom : Koffi Ameko\nNumero $_nomOp : +228 $_num\n\nTelecharge Haya : https://play.google.com/store/apps/details?id=com.flexix.haya';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(backgroundColor: kNuit, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Recevoir', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _OperateurTab(label: 'Tmoney', isActive: _op == 'tmoney', couleur: const Color(0xFF3C3489), onTap: () => setState(() => _op = 'tmoney')),
            _OperateurTab(label: 'Flooz', isActive: _op == 'flooz', couleur: const Color(0xFF854F0B), onTap: () => setState(() => _op = 'flooz')),
          ])),
        const SizedBox(height: 28),
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))]),
          child: Column(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: _op == 'tmoney' ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(20)),
              child: Text(_nomOp, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _op == 'tmoney' ? const Color(0xFF3C3489) : const Color(0xFF854F0B)))),
            const SizedBox(height: 20),
            CustomPaint(size: const Size(200, 200), painter: _QRCodePainter(data: '+228$_num', color: _op == 'tmoney' ? const Color(0xFF3C3489) : const Color(0xFF854F0B))),
            const SizedBox(height: 20),
            Text('+228 $_num', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: 1, color: kNuit)),
            const SizedBox(height: 4), const Text('Koffi Ameko', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ])),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () { Clipboard.setData(ClipboardData(text: '+228 $_num')); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Numero copie !'), backgroundColor: kVert, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); },
            icon: const Icon(Icons.copy, size: 18), label: const Text('Copier le numero', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(backgroundColor: kNuit, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton.icon(onPressed: () => partagerWhatsApp(_msg()),
            icon: const Icon(Icons.chat, size: 18), label: const Text('Partager via WhatsApp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 52,
          child: OutlinedButton.icon(onPressed: () => partagerSMS(_msg()),
            icon: const Icon(Icons.sms_outlined, size: 18, color: kOrange),
            label: const Text('Partager via SMS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kOrange)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: kOrange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 20),
      ])),
    );
  }
}

class _OperateurTab extends StatelessWidget {
  final String label; final bool isActive; final Color couleur; final VoidCallback onTap;
  const _OperateurTab({required this.label, required this.isActive, required this.couleur, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: isActive ? kCardCtx(context) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isActive ? couleur : Colors.grey)))));
}

class _QRCodePainter extends CustomPainter {
  final String data; final Color color;
  const _QRCodePainter({required this.data, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final bg = Paint()..color = Colors.white;
    final c = size.width / 21;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
    final hash = data.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0xFFFFFF);
    void corner(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x*c, y*c, 7*c, 7*c), p);
      canvas.drawRect(Rect.fromLTWH((x+1)*c, (y+1)*c, 5*c, 5*c), bg);
      canvas.drawRect(Rect.fromLTWH((x+2)*c, (y+2)*c, 3*c, 3*c), p);
    }
    corner(0,0); corner(14,0); corner(0,14);
    for (int i = 0; i < 21; i++) for (int j = 0; j < 21; j++) {
      if ((i<8&&j<8)||(i>12&&j<8)||(i<8&&j>12)) continue;
      if (i==6||j==6) { if((i+j)%2==0) canvas.drawRect(Rect.fromLTWH(i*c+1,j*c+1,c-2,c-2),p); continue; }
      if ((hash>>((i*21+j)%24))&1==1) canvas.drawRect(Rect.fromLTWH(i*c+1,j*c+1,c-2,c-2),p);
    }
  }
  @override
  bool shouldRepaint(_QRCodePainter old) => old.data != data || old.color != color;
}

// ─── DEMANDE DE PAIEMENT ─────────────────────────────────
class PaymentRequestScreen extends StatefulWidget {
  const PaymentRequestScreen({super.key});
  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final _montantCtrl = TextEditingController();
  final _objetCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _op = '';

  int get _montant => int.tryParse(_montantCtrl.text) ?? 0;
  bool get _peut => _montant > 0 && _objetCtrl.text.isNotEmpty && _phoneCtrl.text.length == 8;

  String _msg() {
    final ref = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final eur = TauxChangeService.fcfaVersEuros(_montant);
    final opNom = _op == 'tmoney' ? 'Tmoney' : _op == 'flooz' ? 'Flooz' : 'Mobile Money';
    return 'Demande de paiement Haya\n\nDe : Koffi Ameko\nMontant : FCFA ${_montant.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} (~$eur EUR)\nObjet : ${_objetCtrl.text}\nOperateur : $opNom\nRef : #$ref\n\nPour payer ouvre Haya et envoie au :\n+228 ${_phoneCtrl.text}\n\nhttps://play.google.com/store/apps/details?id=com.flexix.haya';
  }

  @override
  Widget build(BuildContext context) {
    final eur = _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(backgroundColor: kNuit, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Demande de paiement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFE7F6EF), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [Icon(Icons.info_outline, color: kVert, size: 20), SizedBox(width: 10),
            Expanded(child: Text('Envoie une demande. Le destinataire paie via Haya !', style: TextStyle(fontSize: 13, color: kVert)))])),
        const SizedBox(height: 20),
        Text('Montant (FCFA)', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kSubtextCtx(context)))),
            Expanded(child: TextField(controller: _montantCtrl, keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: kTextCtx(context)),
                decoration: const InputDecoration(hintText: '0', border: InputBorder.none), onChanged: (_) => setState(() {}))),
          ])),
        if (_montant > 0) Padding(padding: const EdgeInsets.only(top: 6),
            child: Row(children: [const Icon(Icons.euro, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('~$eur EUR', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
        const SizedBox(height: 16),
        Text('Objet', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: TextField(controller: _objetCtrl, style: TextStyle(fontSize: 15, color: kTextCtx(context)),
              decoration: const InputDecoration(hintText: 'Ex: Loyer, Remboursement...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              onChanged: (_) => setState(() {}))),
        const SizedBox(height: 16),
        Text('Ton numero de reception', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('+228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSubtextCtx(context)))),
            Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 8, style: TextStyle(fontSize: 16, color: kTextCtx(context)),
                decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none, counterText: ''),
                onChanged: (v) => setState(() => _op = detectOperateur(v)))),
          ])),
        if (_op == 'tmoney') Padding(padding: const EdgeInsets.only(top: 6), child: const Text('Tmoney', style: TextStyle(color: kNuit, fontSize: 12))),
        if (_op == 'flooz') Padding(padding: const EdgeInsets.only(top: 6), child: const Text('Flooz', style: TextStyle(color: Color(0xFF854F0B), fontSize: 12))),
        if (_peut) ...[
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Apercu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextCtx(context))), const SizedBox(height: 8),
              Text('FCFA ${_montantCtrl.text} (~$eur EUR)', style: TextStyle(fontSize: 12, color: kTextCtx(context))),
              Text('Objet : ${_objetCtrl.text}', style: TextStyle(fontSize: 12, color: kTextCtx(context))),
            ])),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton.icon(onPressed: _peut ? () => partagerWhatsApp(_msg()) : null,
            icon: const Icon(Icons.chat, size: 18), label: const Text('Envoyer via WhatsApp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), disabledBackgroundColor: Colors.grey.shade200, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 52,
          child: OutlinedButton.icon(onPressed: _peut ? () => partagerSMS(_msg()) : null,
            icon: const Icon(Icons.sms_outlined, size: 18, color: kOrange),
            label: const Text('Envoyer via SMS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kOrange)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: kOrange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 10),
        Center(child: Text('Le destinataire paie via Haya', style: TextStyle(fontSize: 11, color: kSubtextCtx(context)))),
      ])),
    );
  }
}

// ─── ÉCRAN ENVOI ─────────────────────────────────────────
class SendScreen extends StatefulWidget {
  final String? numeroInitial;
  const SendScreen({super.key, this.numeroInitial});
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  late final TextEditingController _phoneCtrl;
  final _amountCtrl = TextEditingController();
  String _op = '';

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.numeroInitial ?? '');
    if (widget.numeroInitial != null) _op = detectOperateur(widget.numeroInitial!);
  }

  int get _montant => int.tryParse(_amountCtrl.text) ?? 0;
  int get _frais => _montant > 0 ? (_montant * 0.025).round() : 0;
  int get _total => _montant + _frais;
  String get _eur => _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';
  String get _eurTotal => _total > 0 ? TauxChangeService.fcfaVersEuros(_total) : '0.00';
  bool get _peut => _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 && (_op == 'tmoney' || _op == 'flooz') && _montant > 0;

  void _confirmerPin() => Navigator.push(context, MaterialPageRoute(builder: (_) => PinScreen(
    titre: 'Confirmer le transfert',
    sousTitre: 'PIN pour valider\nFCFA $_montant vers +228 ${_phoneCtrl.text}',
    onSuccess: (_) async { Navigator.pop(context); await _executer(); },
  )));

  Future<void> _executer() async {
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => _TransfertProgressDialog(numero: _phoneCtrl.text, operateur: _op == 'tmoney' ? 'Tmoney' : 'Flooz', montant: _montant));
    await Future.delayed(const Duration(seconds: 1));
    final ref = PayGateService.genererReference();
    final result = await PayGateService.initierPaiement(
      telephone: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      montant: _montant, reseau: PayGateService.convertirOperateur(_op), reference: ref,
    );
    Navigator.pop(context);
    if (result['success']) Navigator.push(context, MaterialPageRoute(
      builder: (_) => SuccessScreen(montant: _montant, numero: _phoneCtrl.text,
          operateur: _op == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)', frais: _frais)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(backgroundColor: kNuit, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Envoyer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [IconButton(icon: const Icon(Icons.people_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())))]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Numero du beneficiaire', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('+228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSubtextCtx(context)))),
            Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 8, style: TextStyle(fontSize: 16, color: kTextCtx(context)),
                decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none, counterText: ''),
                onChanged: (v) => setState(() => _op = detectOperateur(v)))),
          ])),
        const SizedBox(height: 10),
        if (_op == 'tmoney') _OperateurBox(nom: 'Mixx by Yas (Tmoney)', sub: 'Yas Togo', couleur: const Color(0xFFEEEDFE), bordure: const Color(0xFFAFA9EC), textColor: kNuit, logo: 'M'),
        if (_op == 'flooz') _OperateurBox(nom: 'Flooz (Moov Africa)', sub: 'Moov Africa Togo', couleur: const Color(0xFFFFF5EA), bordure: const Color(0xFFFAC775), textColor: const Color(0xFF854F0B), logo: 'F'),
        if (_op == 'inconnu') Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF0F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF7C1C1))),
          child: const Row(children: [Icon(Icons.error_outline, color: kRouge, size: 20), SizedBox(width: 8), Text('Numero non reconnu', style: TextStyle(color: kRouge, fontSize: 13))])),
        const SizedBox(height: 16),
        Text('Montant (FCFA)', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kSubtextCtx(context)))),
            Expanded(child: TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: kTextCtx(context)),
                decoration: const InputDecoration(hintText: '0', border: InputBorder.none), onChanged: (_) => setState(() {}))),
          ])),
        if (_montant > 0) Padding(padding: const EdgeInsets.only(top: 6),
            child: Row(children: [const Icon(Icons.euro, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('~$_eur EUR', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [1000, 2000, 5000, 10000, 25000].map((v) => GestureDetector(
          onTap: () => setState(() => _amountCtrl.text = v.toString()),
          child: Chip(label: Text(v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} '), style: const TextStyle(fontSize: 12)),
            backgroundColor: kCardCtx(context), side: BorderSide(color: kBorderCtx(context)), padding: EdgeInsets.zero))).toList()),
        const SizedBox(height: 16),
        _FeeRow(label: 'Frais (2.5%)', valeur: 'FCFA ${_frais.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}', context: context),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('FCFA ${_total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextCtx(context))),
              if (_total > 0) Text('~$_eurTotal EUR', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ])),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(onPressed: _peut ? _confirmerPin : null,
            style: ElevatedButton.styleFrom(backgroundColor: kNuit, disabledBackgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_peut ? 'Envoyer via ${_op == "tmoney" ? "Tmoney" : "Flooz"}' : 'Confirmer le transfert',
              style: TextStyle(color: _peut ? Colors.white : Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)))),
        const SizedBox(height: 10),
        const Center(child: Text('Securise par PayGate Global · Togo', style: TextStyle(fontSize: 11, color: Colors.grey))),
      ])),
    );
  }
}

class _OperateurBox extends StatelessWidget {
  final String nom, sub, logo; final Color couleur, bordure, textColor;
  const _OperateurBox({required this.nom, required this.sub, required this.logo, required this.couleur, required this.bordure, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(10), border: Border.all(color: bordure)),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(9)),
          child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(nom, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
        Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    ]));
}

class _FeeRow extends StatelessWidget {
  final String label, valeur;
  final BuildContext context;
  const _FeeRow({required this.label, required this.valeur, required this.context});
  @override
  Widget build(BuildContext ctx) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
      Text(valeur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextCtx(context))),
    ]));
}

// ─── SUCCÈS ──────────────────────────────────────────────
class SuccessScreen extends StatefulWidget {
  final int montant, frais; final String numero, operateur;
  const SuccessScreen({super.key, required this.montant, required this.numero, required this.operateur, required this.frais});
  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  late String _ref;

  @override
  void initState() {
    super.initState();
    _ref = 'TG-${(10000 + DateTime.now().millisecond * 9)}';
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _notif(); });
  }

  void _notif() {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(builder: (context) => Positioned(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16,
      child: _NotificationBanner(montant: widget.montant, numero: widget.numero, operateur: widget.operateur, onDismiss: () => e.remove())));
    overlay.insert(e);
    Future.delayed(const Duration(seconds: 4), () { if (e.mounted) e.remove(); });
  }

  void _partager() {
    final eur = TauxChangeService.fcfaVersEuros(widget.montant);
    partagerWhatsApp('Transfert Haya confirme !\n\nMontant : FCFA ${widget.montant} (~$eur EUR)\nVers : +228 ${widget.numero}\nOperateur : ${widget.operateur}\nRef : #$_ref\nFrais : FCFA ${widget.frais}\nStatut : Complete\n\nEnvoye via Haya');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmtDate(DateTime d) {
    const m = ['jan','fev','mars','avr','mai','juin','juil','aout','sep','oct','nov','dec'];
    return '${d.day} ${m[d.month-1]}. ${d.year} ${d.hour.toString().padLeft(2,"0")}h${d.minute.toString().padLeft(2,"0")}';
  }

  @override
  Widget build(BuildContext context) {
    final eur = TauxChangeService.fcfaVersEuros(widget.montant);
    return Scaffold(backgroundColor: kFondCtx(context),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _scale, child: Container(width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFFE7F6EF), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: kVert, size: 48))),
          const SizedBox(height: 20),
          FadeTransition(opacity: _fade, child: Column(children: [
            Text('Transfert envoye !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: kTextCtx(context))),
            const SizedBox(height: 8),
            Text('FCFA ${widget.montant}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -1, color: kNuit)),
            const SizedBox(height: 4),
            Text('~$eur EUR', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Vers +228 ${widget.numero} · ${widget.operateur}', style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
          ])),
          const SizedBox(height: 20),
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorderCtx(context)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Recu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextCtx(context))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE7F6EF), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Complete', style: TextStyle(fontSize: 11, color: kVert, fontWeight: FontWeight.w500))),
              ]),
              const Divider(height: 20),
              _ReceiptRow('Operateur', widget.operateur, context: context),
              _ReceiptRow('Numero', '+228 ${widget.numero}', context: context),
              _ReceiptRow('Reference', '#$_ref', context: context),
              _ReceiptRow('Montant', 'FCFA ${widget.montant} (~$eur EUR)', context: context),
              _ReceiptRow('Frais', 'FCFA ${widget.frais}', context: context),
              _ReceiptRow('Date', _fmtDate(DateTime.now()), context: context),
            ])),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton.icon(onPressed: _partager,
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('Partager via WhatsApp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: kNuit, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Retour a l'accueil", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)))),
        ]))));
  }
}

class _NotificationBanner extends StatefulWidget {
  final int montant; final String numero, operateur; final VoidCallback onDismiss;
  const _NotificationBanner({required this.montant, required this.numero, required this.operateur, required this.onDismiss});
  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SlideTransition(position: _slide,
    child: Material(elevation: 8, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: kNuit, borderRadius: BorderRadius.circular(16), border: Border.all(color: kOrange.withOpacity(0.3))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFE7F6EF), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: kVert, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Transfert confirme', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('FCFA ${widget.montant} vers +228 ${widget.numero}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(widget.operateur, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          GestureDetector(onTap: widget.onDismiss, child: const Icon(Icons.close, color: Colors.white38, size: 18)),
        ]))));
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final BuildContext context;
  const _ReceiptRow(this.label, this.value, {this.valueColor, required this.context});
  @override
  Widget build(BuildContext ctx) => Padding(padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? kTextCtx(context))),
    ]));
}

// ─── HISTORIQUE ──────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filtre = 'tout', _tri = 'date';
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  DateTime? _debut, _fin;
  String _nom = '', _montantQ = '';

  final List<Map<String, dynamic>> _txs = [
    {'i':'AK','nom':'Ama Kpodo','op':'Tmoney','date':'Auj. 10:24','m':'-5 000','mv':5000,'dv':DateTime(2026,4,18),'out':true,'ci':0,'num':'90123456'},
    {'i':'YB','nom':'Yawa Bossa','op':'Flooz','date':'Hier 14:05','m':'+20 000','mv':20000,'dv':DateTime(2026,4,17),'out':false,'ci':1,'num':'94567890'},
    {'i':'KD','nom':'Kofi Dossou','op':'Tmoney','date':'5 avr.','m':'-10 000','mv':10000,'dv':DateTime(2026,4,5),'out':true,'ci':4,'num':'91234567'},
    {'i':'EK','nom':'Edem Klu','op':'Flooz','date':'3 avr.','m':'+50 000','mv':50000,'dv':DateTime(2026,4,3),'out':false,'ci':5,'num':'97654321'},
    {'i':'NA','nom':'Nana Agbeko','op':'Tmoney','date':'1 avr.','m':'-7 500','mv':7500,'dv':DateTime(2026,4,1),'out':true,'ci':2,'num':'91112233'},
    {'i':'PK','nom':'Papa Kojo','op':'Flooz','date':'29 mars','m':'-15 000','mv':15000,'dv':DateTime(2026,3,29),'out':true,'ci':3,'num':'94445566'},
  ];

  List<Map<String, dynamic>> get _filtered {
    var l = _txs.where((t) {
      if (_filtre == 'tmoney' && t['op'] != 'Tmoney') return false;
      if (_filtre == 'flooz' && t['op'] != 'Flooz') return false;
      if (_filtre == 'envois' && t['out'] != true) return false;
      if (_filtre == 'recus' && t['out'] != false) return false;
      if (_nom.isNotEmpty && !t['nom'].toString().toLowerCase().contains(_nom.toLowerCase())) return false;
      if (_montantQ.isNotEmpty) { final m = int.tryParse(_montantQ.replaceAll(' ','')); if (m != null && t['mv'] != m) return false; }
      if (_debut != null && (t['dv'] as DateTime).isBefore(_debut!)) return false;
      if (_fin != null && (t['dv'] as DateTime).isAfter(_fin!)) return false;
      return true;
    }).toList();
    if (_tri == 'nom') l.sort((a, b) => a['nom'].toString().compareTo(b['nom'].toString()));
    else if (_tri == 'montant') l.sort((a, b) => (b['mv'] as int).compareTo(a['mv'] as int));
    else l.sort((a, b) => (b['dv'] as DateTime).compareTo(a['dv'] as DateTime));
    return l;
  }

  void _date(BuildContext context, bool isD) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now(),
        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kNuit, onPrimary: Colors.white)), child: child!));
    if (d != null) setState(() { if (isD) _debut = d; else _fin = d; });
  }

  void _reset() => setState(() { _nom = ''; _montantQ = ''; _debut = null; _fin = null; _nomCtrl.clear(); _montantCtrl.clear(); });
  String _fmt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasF = _nom.isNotEmpty || _montantQ.isNotEmpty || _debut != null || _fin != null;
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(backgroundColor: kNuit, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Activite', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [if (hasF) TextButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh, color: kOrange, size: 16), label: const Text('Reinitialiser', style: TextStyle(color: kOrange, fontSize: 12)))]),
      body: Column(children: [
        Container(color: kCardCtx(context), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _FiltreBtn('Tout','tout',_filtre,(v)=>setState(()=>_filtre=v)),
            _FiltreBtn('Tmoney','tmoney',_filtre,(v)=>setState(()=>_filtre=v)),
            _FiltreBtn('Flooz','flooz',_filtre,(v)=>setState(()=>_filtre=v)),
            _FiltreBtn('Envois','envois',_filtre,(v)=>setState(()=>_filtre=v)),
            _FiltreBtn('Recus','recus',_filtre,(v)=>setState(()=>_filtre=v)),
          ]))),
        Container(color: kFondCtx(context), padding: const EdgeInsets.fromLTRB(16,8,16,4),
          child: Row(children: [
            Text('Trier :', style: TextStyle(fontSize: 12, color: kSubtextCtx(context))), const SizedBox(width: 8),
            _TriBtn('Date','date',_tri,(v)=>setState(()=>_tri=v)), const SizedBox(width: 6),
            _TriBtn('Montant','montant',_tri,(v)=>setState(()=>_tri=v)), const SizedBox(width: 6),
            _TriBtn('Nom','nom',_tri,(v)=>setState(()=>_tri=v)),
            const Spacer(), Text('${_filtered.length} res.', style: TextStyle(fontSize: 11, color: kSubtextCtx(context))),
          ])),
        Container(color: kCardCtx(context), padding: const EdgeInsets.fromLTRB(16,8,16,12),
          child: _tri == 'nom'
              ? TextField(controller: _nomCtrl, onChanged: (v) => setState(()=>_nom=v), style: TextStyle(fontSize: 14, color: kTextCtx(context)),
                  decoration: InputDecoration(hintText: 'Rechercher par nom...', hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_search, color: Colors.grey, size: 20),
                      suffixIcon: _nom.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: ()=>setState((){_nom='';_nomCtrl.clear();})) : null,
                      filled: true, fillColor: kInputCtx(context), contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))
              : _tri == 'montant'
                  ? TextField(controller: _montantCtrl, onChanged: (v) => setState(()=>_montantQ=v), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14, color: kTextCtx(context)),
                      decoration: InputDecoration(hintText: 'Montant exact FCFA', hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.grey, size: 20),
                          suffixIcon: _montantQ.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: ()=>setState((){_montantQ='';_montantCtrl.clear();})) : null,
                          filled: true, fillColor: kInputCtx(context), contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))
                  : Row(children: [
                      Expanded(child: GestureDetector(onTap: ()=>_date(context,true),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [Icon(Icons.calendar_today_outlined, size: 16, color: _debut!=null?kNuit:Colors.grey), const SizedBox(width: 8),
                            Text(_debut!=null?'De : ${_fmt(_debut!)}':'Date debut', style: TextStyle(fontSize: 13, color: _debut!=null?kNuit:Colors.grey)),
                            if (_debut!=null) ...[const Spacer(), GestureDetector(onTap:()=>setState(()=>_debut=null), child: const Icon(Icons.clear, size: 16, color: Colors.grey))],
                          ])))),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(onTap: ()=>_date(context,false),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [Icon(Icons.calendar_today_outlined, size: 16, color: _fin!=null?kNuit:Colors.grey), const SizedBox(width: 8),
                            Text(_fin!=null?'A : ${_fmt(_fin!)}':'Date fin', style: TextStyle(fontSize: 13, color: _fin!=null?kNuit:Colors.grey)),
                            if (_fin!=null) ...[const Spacer(), GestureDetector(onTap:()=>setState(()=>_fin=null), child: const Icon(Icons.clear, size: 16, color: Colors.grey))],
                          ])))),
                    ])),
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,0),
          child: Row(children: [_StatCard('Total envoye','FCFA 37 500',kRouge), const SizedBox(width:10), _StatCard('Total recu','FCFA 70 000',kVert)])),
        Expanded(child: _filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search_off, color: Colors.grey.shade300, size: 48), const SizedBox(height: 12),
                const Text('Aucun resultat', style: TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(height: 6),
                TextButton(onPressed: _reset, child: const Text('Reinitialiser', style: TextStyle(color: kOrange))),
              ]))
            : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filtered.length,
                itemBuilder: (context, i) { final t = _filtered[i];
                  return _TxItemClickable(initiales: t['i'], nom: t['nom'], operateur: t['op'], date: t['date'],
                      montant: t['m'], isOut: t['out'], colorIndex: t['ci']??0, numero: t['num']??''); })),
      ]),
    );
  }
}

class _FiltreBtn extends StatelessWidget {
  final String label, value, current; final Function(String) onTap;
  const _FiltreBtn(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final a = value == current;
    return GestureDetector(onTap: ()=>onTap(value),
      child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: a ? kNuit : kInputCtx(context), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: a ? Colors.white : kSubtextCtx(context)))));
  }
}

class _TriBtn extends StatelessWidget {
  final String label, value, current; final Function(String) onTap;
  const _TriBtn(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final a = value == current;
    return GestureDetector(onTap: ()=>onTap(value),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: a ? kOrange : kCardCtx(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: a ? kOrange : kBorderCtx(context))),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: a ? Colors.white : kSubtextCtx(context)))));
  }
}

class _StatCard extends StatelessWidget {
  final String label, valeur; final Color couleur;
  const _StatCard(this.label, this.valeur, this.couleur);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: kSubtextCtx(context))), const SizedBox(height: 6),
      Text(valeur, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: couleur)),
    ])));
}

// ─── PROFIL ──────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDark;
    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: Column(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)])),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
          child: Column(children: [
            CircleAvatar(radius: 38, backgroundColor: kOrange.withOpacity(0.8),
                child: const Text('KA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600))),
            const SizedBox(height: 14),
            const Text('Koffi Ameko', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            const Text('koffi.ameko@gmail.com', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ProfilStat('47', 'Transferts'),
              Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _ProfilStat('FCFA 284K', 'Envoye'),
              Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _ProfilStat('${ContactsManager.contacts.length}', 'Contacts'),
            ]),
          ])),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Informations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)), const SizedBox(height: 10),
          _ProfilRow(Icons.phone_outlined, 'Telephone', '+228 90 12 34 56'),
          _ProfilRow(Icons.location_on_outlined, 'Pays', 'Togo / Pays-Bas'),
          _ProfilRow(Icons.verified_outlined, 'Compte verifie', 'Oui', valueColor: kVert),
          _ProfilRow(Icons.euro_outlined, 'Taux EUR/FCFA', '1 EUR = ${TauxChangeService.tauxEuroFcfa.toStringAsFixed(2)} FCFA'),
          const SizedBox(height: 18),
          const Text('Securite', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)), const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PinScreen(
              titre: 'Definir le PIN', sousTitre: 'PIN a 4 chiffres pour securiser\nvos transferts',
              onSuccess: (_) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN mis a jour !'), backgroundColor: kVert, behavior: SnackBarBehavior.floating)); },
              modeDefinition: true))),
            child: Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderCtx(context))),
              child: Row(children: [
                const Icon(Icons.lock_outlined, size: 20, color: Colors.grey), const SizedBox(width: 14),
                Expanded(child: Text('PIN de transfert', style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
                Text(PinManager.pinDefini ? 'Defini' : 'Non defini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: PinManager.pinDefini ? kVert : kRouge)),
                const SizedBox(width: 8), Icon(Icons.arrow_forward_ios, size: 14, color: kSubtextCtx(context)),
              ]))),
          const SizedBox(height: 18),
          const Text('Parametres', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)), const SizedBox(height: 10),
          _ProfilRow(Icons.notifications_outlined, 'Notifications', 'Activees'),
          _ProfilRow(Icons.language_outlined, 'Langue', 'Francais'),
          const SizedBox(height: 8),
          // ─── TOGGLE MODE SOMBRE ───
          Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14), margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderCtx(context))),
            child: Row(children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20, color: isDark ? kOrange : Colors.grey),
              const SizedBox(width: 14),
              Expanded(child: Text('Mode sombre', style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
              Switch(
                value: isDark,
                onChanged: (_) { ThemeManager.instance.toggle(); setState(() {}); },
                activeColor: kOrange,
                activeTrackColor: kOrange.withOpacity(0.3),
              ),
            ])),
          const SizedBox(height: 18),
          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
            child: Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderCtx(context))),
              child: Row(children: [
                const Icon(Icons.people_outline, size: 20, color: Colors.grey), const SizedBox(width: 14),
                Expanded(child: Text('Contacts favoris', style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
                Text('${ContactsManager.contacts.length} contacts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSubtextCtx(context))),
                const SizedBox(width: 8), Icon(Icons.arrow_forward_ios, size: 14, color: kSubtextCtx(context)),
              ]))),
          GestureDetector(
            onTap: () async { final url = Uri.parse('https://coursiertogo.github.io/haya-privacy/privacy_policy.html'); if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication); },
            child: Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderCtx(context))),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.grey), const SizedBox(width: 14),
                Expanded(child: Text('A propos de Haya', style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
                const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
              ]))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50,
            child: OutlinedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Se deconnecter', style: TextStyle(color: Colors.grey, fontSize: 15)))),
        ])),
      ]),
    );
  }
}

class _ProfilStat extends StatelessWidget {
  final String valeur, label;
  const _ProfilStat(this.valeur, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
    const SizedBox(height: 3), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);
}

class _ProfilRow extends StatelessWidget {
  final IconData icon; final String label, valeur; final Color? valueColor;
  const _ProfilRow(this.icon, this.label, this.valeur, {this.valueColor});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderCtx(context))),
    child: Row(children: [
      Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 14),
      Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
      Text(valeur, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? kSubtextCtx(context))),
    ]));
}

// ─── CONNEXION ───────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: kNuit, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.arrow_upward, color: kOrange, size: 26)),
          const SizedBox(width: 14),
          Text('haya', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: kTextCtx(context), letterSpacing: -1)),
        ]),
        const SizedBox(height: 10),
        Text("Envoie. C'est parti.", style: TextStyle(fontSize: 15, color: kSubtextCtx(context))),
        const SizedBox(height: 40),
        Container(decoration: BoxDecoration(color: kInputCtx(context), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: GestureDetector(onTap: ()=>setState(()=>_isLogin=true),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _isLogin ? kCardCtx(context) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text('Connexion', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _isLogin ? kTextCtx(context) : kSubtextCtx(context)))))),
            Expanded(child: GestureDetector(onTap: ()=>setState(()=>_isLogin=false),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: !_isLogin ? kCardCtx(context) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text('Inscription', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: !_isLogin ? kTextCtx(context) : kSubtextCtx(context)))))),
          ])),
        const SizedBox(height: 28),
        Text('Numero', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('+228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSubtextCtx(context)))),
            Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: TextStyle(fontSize: 16, color: kTextCtx(context)),
                decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none))),
          ])),
        const SizedBox(height: 16),
        Text('Mot de passe', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))), const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: kCardCtx(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderCtx(context))),
          child: TextField(controller: _passCtrl, obscureText: true, style: TextStyle(fontSize: 16, color: kTextCtx(context)),
              decoration: const InputDecoration(hintText: '........', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false),
            style: ElevatedButton.styleFrom(backgroundColor: kNuit, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_isLogin ? 'Se connecter' : 'Creer mon compte', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)))),
        const SizedBox(height: 18),
        Center(child: Text(_isLogin ? "Pas encore de compte ? Inscris-toi" : "Deja un compte ? Connecte-toi",
            style: TextStyle(fontSize: 13, color: kSubtextCtx(context)))),
      ]))),
    );
  }
}
