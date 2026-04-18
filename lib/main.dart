import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'paygate_service.dart';

void main() {
  runApp(const HayaApp());
}

class HayaApp extends StatelessWidget {
  const HayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'haya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          primary: const Color(0xFF0D0D2B),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

const kNuit = Color(0xFF0D0D2B);
const kOrange = Color(0xFFF97316);
const kVert = Color(0xFF1D9E75);
const kFond = Color(0xFFF5F4FF);
const kRouge = Color(0xFFE24B4A);

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

// ─── PARTAGE VIA WHATSAPP / SMS ──────────────────────────
Future<void> partagerWhatsApp(String message) async {
  final encoded = Uri.encodeComponent(message);
  final url = Uri.parse('https://wa.me/?text=$encoded');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> partagerSMS(String message) async {
  final encoded = Uri.encodeComponent(message);
  final url = Uri.parse('sms:?body=$encoded');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ─── SERVICE TAUX DE CHANGE ──────────────────────────────
class TauxChangeService {
  static double _tauxEuroFcfa = 655.957;
  static bool _charge = false;

  static double get tauxEuroFcfa => _tauxEuroFcfa;

  static Future<void> chargerTaux() async {
    if (_charge) return;
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/EUR'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final taux = data['rates']['XOF'];
        if (taux != null) {
          _tauxEuroFcfa = (taux as num).toDouble();
          _charge = true;
        }
      }
    } catch (_) {}
  }

  static String fcfaVersEuros(int montantFcfa) {
    final euros = montantFcfa / _tauxEuroFcfa;
    return euros.toStringAsFixed(2);
  }
}

// ─── MODÈLE CONTACT ──────────────────────────────────────
class Contact {
  final String nom;
  final String numero;
  final String operateur;
  final int colorIndex;
  Contact({required this.nom, required this.numero, required this.operateur, required this.colorIndex});
}

// ─── GESTIONNAIRE CONTACTS ────────────────────────────────
class ContactsManager {
  static final List<Contact> contacts = [
    Contact(nom: 'Ama Kpodo', numero: '90123456', operateur: 'tmoney', colorIndex: 0),
    Contact(nom: 'Yawa Bossa', numero: '94567890', operateur: 'flooz', colorIndex: 1),
    Contact(nom: 'Kofi Dossou', numero: '91234567', operateur: 'tmoney', colorIndex: 4),
    Contact(nom: 'Edem Klu', numero: '97654321', operateur: 'flooz', colorIndex: 5),
  ];
}

// ─── ÉCRAN PRINCIPAL ─────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    TauxChangeService.chargerTaux();
  }

  final List<Widget> _screens = const [
    HomeScreen(), SendScreen(), HistoryScreen(), ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kOrange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedIconTheme: const IconThemeData(color: kOrange, size: 26),
        unselectedIconTheme: const IconThemeData(color: Colors.grey, size: 22),
        onTap: (index) => setState(() => _currentIndex = index),
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

// ─── ÉCRAN ACCUEIL ───────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)]),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 34, height: 34,
                    decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                const Text('haya', style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w500, letterSpacing: -0.5)),
              ]),
              CircleAvatar(radius: 18, backgroundColor: kOrange.withOpacity(0.3),
                  child: const Text('KA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 18),
            const Text('Bonjour, Koffi !', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24)),
              child: const Row(children: [
                Icon(Icons.lock_outline, color: Colors.white54, size: 18),
                SizedBox(width: 10),
                Text('Connectez votre compte pour voir votre solde',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const Text('Togo · Mode local', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                _CompactAction(icon: Icons.history, label: 'Historique',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Contacts favoris', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())).then((_) => setState(() {})),
              child: const Text('Gerer', style: TextStyle(fontSize: 13, color: kOrange, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ContactsManager.contacts.length + 1,
            itemBuilder: (context, i) {
              if (i == ContactsManager.contacts.length) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())).then((_) => setState(() {})),
                  child: Container(
                    width: 60, margin: const EdgeInsets.only(right: 12),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 48, height: 48,
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300)),
                          child: const Icon(Icons.add, color: Colors.grey, size: 22)),
                      const SizedBox(height: 4),
                      const Text('Ajouter', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  ),
                );
              }
              final c = ContactsManager.contacts[i];
              final initiales = c.nom.split(' ').map((e) => e[0]).take(2).join();
              final bgColor = avatarColors[c.colorIndex % avatarColors.length];
              final textColor = avatarTextColors[c.colorIndex % avatarTextColors.length];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SendScreen(numeroInitial: c.numero))),
                child: Container(
                  width: 60, margin: const EdgeInsets.only(right: 12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(radius: 24, backgroundColor: bgColor,
                        child: Text(initiales, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
                    const SizedBox(height: 4),
                    Text(c.nom.split(' ')[0], style: const TextStyle(fontSize: 11, color: Colors.black87),
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Transactions recentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              child: const Text('Voir tout', style: TextStyle(fontSize: 13, color: kOrange, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: const [
            _TxItem(initiales: 'AK', nom: 'Ama Kpodo', operateur: 'Tmoney', date: 'Auj. 10:24', montant: '-5 000', isOut: true, colorIndex: 0),
            _TxItem(initiales: 'YB', nom: 'Yawa Bossa', operateur: 'Flooz', date: 'Hier 14:05', montant: '+20 000', isOut: false, colorIndex: 1),
            _TxItem(initiales: 'KD', nom: 'Kofi Dossou', operateur: 'Tmoney', date: '5 avr.', montant: '-10 000', isOut: true, colorIndex: 4),
            _TxItem(initiales: 'EK', nom: 'Edem Klu', operateur: 'Flooz', date: '3 avr.', montant: '+50 000', isOut: false, colorIndex: 5),
            _TxItem(initiales: 'NA', nom: 'Nana Agbeko', operateur: 'Tmoney', date: '1 avr.', montant: '-7 500', isOut: true, colorIndex: 2),
          ]),
        ),
      ]),
    );
  }
}

// ─── ÉCRAN DEMANDE DE PAIEMENT ───────────────────────────
class PaymentRequestScreen extends StatefulWidget {
  const PaymentRequestScreen({super.key});
  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final _montantCtrl = TextEditingController();
  final _objetCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _operateur = '';

  int get _montant => int.tryParse(_montantCtrl.text) ?? 0;

  bool get _peutDemander =>
      _montant > 0 && _objetCtrl.text.isNotEmpty && _phoneCtrl.text.length == 8;

  String _buildMessage() {
    final ref = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final euros = TauxChangeService.fcfaVersEuros(_montant);
    final operateurNom = _operateur == 'tmoney' ? 'Tmoney' : _operateur == 'flooz' ? 'Flooz' : 'Mobile Money';
    return 'Demande de paiement Haya\n\n'
        'De : Koffi Ameko\n'
        'Montant : FCFA ${_montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} (~$euros EUR)\n'
        'Objet : ${_objetCtrl.text}\n'
        'Operateur : $operateurNom\n'
        'Reference : #$ref\n\n'
        'Pour payer, ouvre Haya et envoie le montant au :\n'
        '+228 ${_phoneCtrl.text}\n\n'
        'Telecharge Haya :\n'
        'https://play.google.com/store/apps/details?id=com.flexix.haya';
  }

  @override
  Widget build(BuildContext context) {
    final euros = _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';

    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Demande de paiement',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFE7F6EF), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: kVert, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Envoie une demande de paiement. Le destinataire n\'a qu\'a confirmer !',
                style: TextStyle(fontSize: 13, color: kVert))),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Montant demande (FCFA)', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey))),
              Expanded(child: TextField(controller: _montantCtrl, keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                  onChanged: (_) => setState(() {}))),
            ]),
          ),
          if (_montant > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                const Icon(Icons.euro, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Equivalent : $euros EUR', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          const SizedBox(height: 16),
          const Text('Objet du paiement', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: TextField(controller: _objetCtrl,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                    hintText: 'Ex: Loyer janvier, Remboursement...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                onChanged: (_) => setState(() {})),
          ),
          const SizedBox(height: 16),
          const Text('Ton numero de reception', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('+228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey))),
              Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                  maxLength: 8, style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none, counterText: ''),
                  onChanged: (v) => setState(() { _operateur = detectOperateur(v); }))),
            ]),
          ),
          if (_operateur == 'tmoney')
            Padding(padding: const EdgeInsets.only(top: 6),
                child: Text('Tmoney (Mixx by Yas)', style: TextStyle(color: kNuit.withOpacity(0.7), fontSize: 12))),
          if (_operateur == 'flooz')
            Padding(padding: const EdgeInsets.only(top: 6),
                child: Text('Flooz (Moov Africa)', style: TextStyle(color: const Color(0xFF854F0B).withOpacity(0.8), fontSize: 12))),

          // Aperçu
          if (_peutDemander) ...[
            const SizedBox(height: 20),
            const Text('Apercu du message', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Demande de paiement Haya', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kNuit)),
                const SizedBox(height: 8),
                Text('Montant : FCFA ${_montantCtrl.text} (~$euros EUR)',
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                Text('Objet : ${_objetCtrl.text}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                Text('Numero : +228 ${_phoneCtrl.text}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // Bouton WhatsApp
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _peutDemander ? () => partagerWhatsApp(_buildMessage()) : null,
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('Envoyer via WhatsApp',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 10),

          // Bouton SMS
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: _peutDemander ? () => partagerSMS(_buildMessage()) : null,
              icon: const Icon(Icons.sms_outlined, size: 18, color: kOrange),
              label: const Text('Envoyer via SMS',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kOrange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kOrange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 10),
          const Center(child: Text('Le destinataire recoit le message et paie via Haya',
              style: TextStyle(fontSize: 11, color: Colors.grey))),
        ]),
      ),
    );
  }
}

// ─── ÉCRAN CONTACTS FAVORIS ──────────────────────────────
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  void _ajouterContact() {
    final nomCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final operateur = numCtrl.text.length >= 2 ? detectOperateur(numCtrl.text) : '';
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nouveau contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kNuit)),
              const SizedBox(height: 20),
              const Text('Nom complet', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: TextField(controller: nomCtrl, style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(hintText: 'Ex: Ama Kpodo',
                        border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
              ),
              const SizedBox(height: 16),
              const Text('Numero de telephone', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('+228', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500))),
                  Expanded(child: TextField(controller: numCtrl, keyboardType: TextInputType.phone, maxLength: 8,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none, counterText: ''),
                      onChanged: (_) => setModalState(() {}))),
                ]),
              ),
              if (operateur == 'tmoney')
                Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text('Tmoney (Mixx by Yas)', style: TextStyle(color: kNuit.withOpacity(0.7), fontSize: 12))),
              if (operateur == 'flooz')
                Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text('Flooz (Moov Africa)', style: TextStyle(color: const Color(0xFF854F0B).withOpacity(0.8), fontSize: 12))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (nomCtrl.text.isNotEmpty && numCtrl.text.length == 8 &&
                        (operateur == 'tmoney' || operateur == 'flooz')) {
                      setState(() {
                        ContactsManager.contacts.add(Contact(
                          nom: nomCtrl.text, numero: numCtrl.text, operateur: operateur,
                          colorIndex: ContactsManager.contacts.length % avatarColors.length));
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kNuit,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Ajouter le contact',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          );
        },
      ),
    );
  }

  void _supprimerContact(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le contact ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text('Voulez-vous supprimer ${ContactsManager.contacts[index].nom} ?',
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () { setState(() => ContactsManager.contacts.removeAt(index)); Navigator.pop(context); },
            child: const Text('Supprimer', style: TextStyle(color: kRouge)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Contacts favoris', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [IconButton(icon: const Icon(Icons.person_add_outlined, color: Colors.white), onPressed: _ajouterContact)],
      ),
      body: ContactsManager.contacts.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, color: Colors.grey.shade300, size: 64),
              const SizedBox(height: 16),
              const Text('Aucun contact favori', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _ajouterContact,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un contact'),
                style: ElevatedButton.styleFrom(backgroundColor: kNuit, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ContactsManager.contacts.length,
              itemBuilder: (context, i) {
                final c = ContactsManager.contacts[i];
                final initiales = c.nom.split(' ').map((e) => e[0]).take(2).join();
                final bgColor = avatarColors[c.colorIndex % avatarColors.length];
                final textColor = avatarTextColors[c.colorIndex % avatarTextColors.length];
                final isTmoney = c.operateur == 'tmoney';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    CircleAvatar(radius: 24, backgroundColor: bgColor,
                        child: Text(initiales, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isTmoney ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
                            borderRadius: BorderRadius.circular(4)),
                          child: Text(isTmoney ? 'Tmoney' : 'Flooz',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500,
                                  color: isTmoney ? kNuit : const Color(0xFF854F0B))),
                        ),
                        const SizedBox(width: 6),
                        Text('+228 ${c.numero}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ])),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SendScreen(numeroInitial: c.numero))),
                      child: Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.send_outlined, color: kOrange, size: 20)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _supprimerContact(i),
                      child: Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kRouge.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.delete_outline, color: kRouge, size: 20)),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: ContactsManager.contacts.isNotEmpty
          ? FloatingActionButton(onPressed: _ajouterContact, backgroundColor: kOrange,
              child: const Icon(Icons.person_add_outlined, color: Colors.white))
          : null,
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: Colors.white24);
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CompactAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: kOrange, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}

class _TxItem extends StatelessWidget {
  final String initiales, nom, operateur, date, montant;
  final bool isOut;
  final int colorIndex;
  const _TxItem({required this.initiales, required this.nom, required this.operateur,
      required this.date, required this.montant, required this.isOut, this.colorIndex = 0});

  @override
  Widget build(BuildContext context) {
    final isTmoney = operateur == 'Tmoney';
    final bgColor = avatarColors[colorIndex % avatarColors.length];
    final textColor = avatarTextColors[colorIndex % avatarTextColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: bgColor,
            child: Text(initiales, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isTmoney ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(4)),
              child: Text(operateur, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500,
                  color: isTmoney ? kNuit : const Color(0xFF854F0B))),
            ),
            const SizedBox(width: 6),
            Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ])),
        Text(montant, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
            color: isOut ? kRouge : kVert)),
      ]),
    );
  }
}

// ─── ÉCRAN RECEVOIR ──────────────────────────────────────
class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String _operateurSelectionne = 'tmoney';
  final String _numeroTmoney = '90123456';
  final String _numeroFlooz = '94123456';
  final String _nomUtilisateur = 'Koffi Ameko';

  String get _numeroCourant => _operateurSelectionne == 'tmoney' ? _numeroTmoney : _numeroFlooz;
  String get _nomOperateur => _operateurSelectionne == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';

  void _copierNumero(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '+228 $_numeroCourant'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Numero copie !'), backgroundColor: kVert,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _buildShareMessage() =>
      'Envoie-moi de l\'argent sur Haya !\n\nNom : $_nomUtilisateur\nNumero $_nomOperateur : +228 $_numeroCourant\n\nTelecharge Haya : https://play.google.com/store/apps/details?id=com.flexix.haya';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Recevoir de l\'argent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _OperateurTab(label: 'Tmoney', isActive: _operateurSelectionne == 'tmoney',
                  couleur: const Color(0xFF3C3489), onTap: () => setState(() => _operateurSelectionne = 'tmoney')),
              _OperateurTab(label: 'Flooz', isActive: _operateurSelectionne == 'flooz',
                  couleur: const Color(0xFF854F0B), onTap: () => setState(() => _operateurSelectionne = 'flooz')),
            ]),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))]),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _operateurSelectionne == 'tmoney' ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(_nomOperateur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                    color: _operateurSelectionne == 'tmoney' ? const Color(0xFF3C3489) : const Color(0xFF854F0B))),
              ),
              const SizedBox(height: 20),
              CustomPaint(size: const Size(200, 200),
                  painter: _QRCodePainter(data: '+228$_numeroCourant',
                      color: _operateurSelectionne == 'tmoney' ? const Color(0xFF3C3489) : const Color(0xFF854F0B))),
              const SizedBox(height: 20),
              Text('+228 $_numeroCourant', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: 1, color: kNuit)),
              const SizedBox(height: 4),
              Text(_nomUtilisateur, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE7F6EF), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: kVert, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Montre ce QR code ou partage ton numero pour recevoir directement sur $_nomOperateur.',
                  style: const TextStyle(fontSize: 13, color: kVert))),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _copierNumero(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copier le numero', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(backgroundColor: kNuit, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
          const SizedBox(height: 10),
          // Bouton WhatsApp
          SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () => partagerWhatsApp(_buildShareMessage()),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Partager via WhatsApp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
          const SizedBox(height: 10),
          // Bouton SMS
          SizedBox(width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: () => partagerSMS(_buildShareMessage()),
                icon: const Icon(Icons.sms_outlined, size: 18, color: kOrange),
                label: const Text('Partager via SMS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kOrange)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: kOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _OperateurTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color couleur;
  final VoidCallback onTap;
  const _OperateurTab({required this.label, required this.isActive, required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isActive ? couleur : Colors.grey)),
        ),
      ),
    );
  }
}

class _QRCodePainter extends CustomPainter {
  final String data;
  final Color color;
  const _QRCodePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final bgPaint = Paint()..color = Colors.white;
    final double cell = size.width / 21;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final hash = data.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0xFFFFFF);
    void drawCorner(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, 7 * cell, 7 * cell), paint);
      canvas.drawRect(Rect.fromLTWH((x + 1) * cell, (y + 1) * cell, 5 * cell, 5 * cell), bgPaint);
      canvas.drawRect(Rect.fromLTWH((x + 2) * cell, (y + 2) * cell, 3 * cell, 3 * cell), paint);
    }
    drawCorner(0, 0); drawCorner(14, 0); drawCorner(0, 14);
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        if ((i < 8 && j < 8) || (i > 12 && j < 8) || (i < 8 && j > 12)) continue;
        if (i == 6 || j == 6) {
          if ((i + j) % 2 == 0) canvas.drawRect(Rect.fromLTWH(i * cell + 1, j * cell + 1, cell - 2, cell - 2), paint);
          continue;
        }
        final v = (hash >> ((i * 21 + j) % 24)) & 1;
        if (v == 1) canvas.drawRect(Rect.fromLTWH(i * cell + 1, j * cell + 1, cell - 2, cell - 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QRCodePainter old) => old.data != data || old.color != color;
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
  String _operateur = '';

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.numeroInitial ?? '');
    if (widget.numeroInitial != null) _operateur = detectOperateur(widget.numeroInitial!);
  }

  int get _montant => int.tryParse(_amountCtrl.text) ?? 0;
  int get _frais => _montant > 0 ? (_montant * 0.025).round() : 0;
  int get _total => _montant + _frais;
  String get _euros => _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';
  String get _eurosTotal => _total > 0 ? TauxChangeService.fcfaVersEuros(_total) : '0.00';

  bool get _peutEnvoyer =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
      (_operateur == 'tmoney' || _operateur == 'flooz') && _montant > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Envoyer de l\'argent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const Text('Numero du beneficiaire', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('+228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey))),
              Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                  maxLength: 8, style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none, counterText: ''),
                  onChanged: (v) => setState(() { _operateur = detectOperateur(v); }))),
            ]),
          ),
          const SizedBox(height: 10),
          if (_operateur == 'tmoney')
            _OperateurBox(nom: 'Mixx by Yas (Tmoney)', sub: 'Yas Togo',
                couleur: const Color(0xFFEEEDFE), bordure: const Color(0xFFAFA9EC), textColor: kNuit, logo: 'M'),
          if (_operateur == 'flooz')
            _OperateurBox(nom: 'Flooz (Moov Africa)', sub: 'Moov Africa Togo',
                couleur: const Color(0xFFFFF5EA), bordure: const Color(0xFFFAC775),
                textColor: const Color(0xFF854F0B), logo: 'F'),
          if (_operateur == 'inconnu')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF0F0), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF7C1C1))),
              child: const Row(children: [
                Icon(Icons.error_outline, color: kRouge, size: 20),
                SizedBox(width: 8),
                Text('Numero non reconnu', style: TextStyle(color: kRouge, fontSize: 13)),
              ]),
            ),
          const SizedBox(height: 16),
          const Text('Montant (FCFA)', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey))),
              Expanded(child: TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                  onChanged: (_) => setState(() {}))),
            ]),
          ),
          if (_montant > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                const Icon(Icons.euro, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Equivalent : $_euros EUR', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [1000, 2000, 5000, 10000, 25000].map((v) => GestureDetector(
            onTap: () => setState(() => _amountCtrl.text = v.toString()),
            child: Chip(
              label: Text(v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} '),
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade300), padding: EdgeInsets.zero),
          )).toList()),
          const SizedBox(height: 16),
          _FeeRow(label: 'Frais PayGate (2.5%)',
              valeur: 'FCFA ${_frais.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total debite', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('FCFA ${_total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                if (_total > 0)
                  Text('~$_eurosTotal EUR', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _peutEnvoyer ? () async {
                showDialog(context: context, barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()));
                final ref = PayGateService.genererReference();
                final result = await PayGateService.initierPaiement(
                  telephone: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
                  montant: _montant, reseau: PayGateService.convertirOperateur(_operateur), reference: ref,
                );
                Navigator.pop(context);
                if (result['success']) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SuccessScreen(montant: _montant, numero: _phoneCtrl.text,
                        operateur: _operateur == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)',
                        frais: _frais),
                  ));
                }
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: kNuit,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(
                _peutEnvoyer ? 'Envoyer via ${_operateur == 'tmoney' ? 'Tmoney' : 'Flooz'}' : 'Confirmer le transfert',
                style: TextStyle(color: _peutEnvoyer ? Colors.white : Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(child: Text('Securise par PayGate Global · Togo',
              style: TextStyle(fontSize: 11, color: Colors.grey))),
        ]),
      ),
    );
  }
}

class _OperateurBox extends StatelessWidget {
  final String nom, sub, logo;
  final Color couleur, bordure, textColor;
  const _OperateurBox({required this.nom, required this.sub, required this.logo,
      required this.couleur, required this.bordure, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(10), border: Border.all(color: bordure)),
      child: Row(children: [
        Container(width: 34, height: 34,
            decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ]),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label, valeur;
  const _FeeRow({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(valeur, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── ÉCRAN SUCCÈS ─────────────────────────────────────────
class SuccessScreen extends StatefulWidget {
  final int montant, frais;
  final String numero, operateur;
  const SuccessScreen({super.key, required this.montant, required this.numero,
      required this.operateur, required this.frais});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late String _ref;

  @override
  void initState() {
    super.initState();
    _ref = 'TG-${(10000 + DateTime.now().millisecond * 9).toString()}';
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _afficherNotificationInApp();
    });
  }

  void _afficherNotificationInApp() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16, right: 16,
        child: _NotificationBanner(montant: widget.montant, numero: widget.numero,
            operateur: widget.operateur, onDismiss: () => entry.remove()),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () { if (entry.mounted) entry.remove(); });
  }

  void _partagerRecu() {
    final euros = TauxChangeService.fcfaVersEuros(widget.montant);
    final message = 'Transfert Haya confirme !\n\n'
        'Montant : FCFA ${widget.montant} (~$euros EUR)\n'
        'Vers : +228 ${widget.numero}\n'
        'Operateur : ${widget.operateur}\n'
        'Reference : #$_ref\n'
        'Frais : FCFA ${widget.frais}\n'
        'Statut : Complete\n\nEnvoye via Haya - Togo';
    partagerWhatsApp(message);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _formatDate(DateTime d) {
    const mois = ['jan', 'fev', 'mars', 'avr', 'mai', 'juin', 'juil', 'aout', 'sep', 'oct', 'nov', 'dec'];
    return '${d.day} ${mois[d.month - 1]}. ${d.year} ${d.hour.toString().padLeft(2, "0")}h${d.minute.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final euros = TauxChangeService.fcfaVersEuros(widget.montant);
    return Scaffold(
      backgroundColor: kFond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(scale: _scaleAnim,
                child: Container(width: 80, height: 80,
                    decoration: const BoxDecoration(color: Color(0xFFE7F6EF), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: kVert, size: 48))),
            const SizedBox(height: 20),
            FadeTransition(opacity: _fadeAnim, child: Column(children: [
              const Text('Transfert envoye !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('FCFA ${widget.montant}', style: const TextStyle(fontSize: 36,
                  fontWeight: FontWeight.w600, letterSpacing: -1, color: kNuit)),
              const SizedBox(height: 4),
              Text('~$euros EUR', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Vers +228 ${widget.numero} · ${widget.operateur}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
            ])),
            const SizedBox(height: 20),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Recu de transfert', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kNuit)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE7F6EF), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Complete', style: TextStyle(fontSize: 11, color: kVert, fontWeight: FontWeight.w500)),
                  ),
                ]),
                const Divider(height: 20),
                _ReceiptRow('Operateur', widget.operateur),
                _ReceiptRow('Numero', '+228 ${widget.numero}'),
                _ReceiptRow('Reference', '#$_ref'),
                _ReceiptRow('Montant', 'FCFA ${widget.montant} (~$euros EUR)'),
                _ReceiptRow('Frais', 'FCFA ${widget.frais}'),
                _ReceiptRow('Date', _formatDate(DateTime.now())),
              ]),
            ),
            const SizedBox(height: 16),
            // Partager reçu via WhatsApp directement
            SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: _partagerRecu,
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Partager le recu via WhatsApp',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: kNuit,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Retour a l'accueil",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                )),
          ]),
        ),
      ),
    );
  }
}

class _NotificationBanner extends StatefulWidget {
  final int montant;
  final String numero, operateur;
  final VoidCallback onDismiss;
  const _NotificationBanner({required this.montant, required this.numero,
      required this.operateur, required this.onDismiss});

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: Material(elevation: 8, borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: kNuit, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kOrange.withOpacity(0.3))),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFE7F6EF), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: kVert, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Transfert confirme', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('FCFA ${widget.montant} vers +228 ${widget.numero}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(widget.operateur, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              GestureDetector(onTap: widget.onDismiss,
                  child: const Icon(Icons.close, color: Colors.white38, size: 18)),
            ]),
          )),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ReceiptRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? Colors.black)),
      ]),
    );
  }
}

// ─── ÉCRAN HISTORIQUE ────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filtre = 'tout';
  String _triPar = 'date';
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _rechercheNom = '';
  String _rechercheMontant = '';

  final List<Map<String, dynamic>> _transactions = [
    {'initiales': 'AK', 'nom': 'Ama Kpodo', 'op': 'Tmoney', 'date': 'Auj. 10:24', 'montant': '-5 000', 'montantVal': 5000, 'dateVal': DateTime(2026, 4, 18), 'out': true, 'ci': 0},
    {'initiales': 'YB', 'nom': 'Yawa Bossa', 'op': 'Flooz', 'date': 'Hier 14:05', 'montant': '+20 000', 'montantVal': 20000, 'dateVal': DateTime(2026, 4, 17), 'out': false, 'ci': 1},
    {'initiales': 'KD', 'nom': 'Kofi Dossou', 'op': 'Tmoney', 'date': '5 avr.', 'montant': '-10 000', 'montantVal': 10000, 'dateVal': DateTime(2026, 4, 5), 'out': true, 'ci': 4},
    {'initiales': 'EK', 'nom': 'Edem Klu', 'op': 'Flooz', 'date': '3 avr.', 'montant': '+50 000', 'montantVal': 50000, 'dateVal': DateTime(2026, 4, 3), 'out': false, 'ci': 5},
    {'initiales': 'NA', 'nom': 'Nana Agbeko', 'op': 'Tmoney', 'date': '1 avr.', 'montant': '-7 500', 'montantVal': 7500, 'dateVal': DateTime(2026, 4, 1), 'out': true, 'ci': 2},
    {'initiales': 'PK', 'nom': 'Papa Kojo', 'op': 'Flooz', 'date': '29 mars', 'montant': '-15 000', 'montantVal': 15000, 'dateVal': DateTime(2026, 3, 29), 'out': true, 'ci': 3},
  ];

  List<Map<String, dynamic>> get _filtered {
    var liste = _transactions.where((t) {
      if (_filtre == 'tmoney' && t['op'] != 'Tmoney') return false;
      if (_filtre == 'flooz' && t['op'] != 'Flooz') return false;
      if (_filtre == 'envois' && t['out'] != true) return false;
      if (_filtre == 'recus' && t['out'] != false) return false;
      if (_rechercheNom.isNotEmpty && !t['nom'].toString().toLowerCase().contains(_rechercheNom.toLowerCase())) return false;
      if (_rechercheMontant.isNotEmpty) {
        final m = int.tryParse(_rechercheMontant.replaceAll(' ', ''));
        if (m != null && t['montantVal'] != m) return false;
      }
      if (_dateDebut != null && (t['dateVal'] as DateTime).isBefore(_dateDebut!)) return false;
      if (_dateFin != null && (t['dateVal'] as DateTime).isAfter(_dateFin!)) return false;
      return true;
    }).toList();
    if (_triPar == 'nom') liste.sort((a, b) => a['nom'].toString().compareTo(b['nom'].toString()));
    else if (_triPar == 'montant') liste.sort((a, b) => (b['montantVal'] as int).compareTo(a['montantVal'] as int));
    else liste.sort((a, b) => (b['dateVal'] as DateTime).compareTo(a['dateVal'] as DateTime));
    return liste;
  }

  void _choisirDate(BuildContext context, bool isDebut) async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kNuit, onPrimary: Colors.white)),
        child: child!),
    );
    if (date != null) setState(() { if (isDebut) _dateDebut = date; else _dateFin = date; });
  }

  void _reinitialiser() {
    setState(() {
      _rechercheNom = ''; _rechercheMontant = '';
      _dateDebut = null; _dateFin = null;
      _nomCtrl.clear(); _montantCtrl.clear();
    });
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasFilters = _rechercheNom.isNotEmpty || _rechercheMontant.isNotEmpty || _dateDebut != null || _dateFin != null;
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Activite', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          if (hasFilters) TextButton.icon(
            onPressed: _reinitialiser,
            icon: const Icon(Icons.refresh, color: kOrange, size: 16),
            label: const Text('Reinitialiser', style: TextStyle(color: kOrange, fontSize: 12)),
          ),
        ],
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FiltreBtn('Tout', 'tout', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Tmoney', 'tmoney', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Flooz', 'flooz', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Envois', 'envois', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Recus', 'recus', _filtre, (v) => setState(() => _filtre = v)),
            ]),
          ),
        ),
        Container(color: kFond, padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            const Text('Trier par :', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            _TriBtn('Date', 'date', _triPar, (v) => setState(() => _triPar = v)),
            const SizedBox(width: 6),
            _TriBtn('Montant', 'montant', _triPar, (v) => setState(() => _triPar = v)),
            const SizedBox(width: 6),
            _TriBtn('Nom', 'nom', _triPar, (v) => setState(() => _triPar = v)),
            const Spacer(),
            Text('${_filtered.length} resultat(s)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _triPar == 'nom'
              ? TextField(controller: _nomCtrl, onChanged: (v) => setState(() => _rechercheNom = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(hintText: 'Rechercher par nom...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_search, color: Colors.grey, size: 20),
                      suffixIcon: _rechercheNom.isNotEmpty ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () => setState(() { _rechercheNom = ''; _nomCtrl.clear(); })) : null,
                      filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))
              : _triPar == 'montant'
                  ? TextField(controller: _montantCtrl, onChanged: (v) => setState(() => _rechercheMontant = v),
                      keyboardType: TextInputType.number, style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(hintText: 'Montant exact en FCFA (ex: 5000)',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.grey, size: 20),
                          suffixIcon: _rechercheMontant.isNotEmpty ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () => setState(() { _rechercheMontant = ''; _montantCtrl.clear(); })) : null,
                          filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))
                  : Row(children: [
                      Expanded(child: GestureDetector(onTap: () => _choisirDate(context, true),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: _dateDebut != null ? kNuit : Colors.grey),
                            const SizedBox(width: 8),
                            Text(_dateDebut != null ? 'De : ${_formatDate(_dateDebut!)}' : 'Date de debut',
                                style: TextStyle(fontSize: 13, color: _dateDebut != null ? kNuit : Colors.grey)),
                            if (_dateDebut != null) ...[const Spacer(),
                              GestureDetector(onTap: () => setState(() => _dateDebut = null),
                                  child: const Icon(Icons.clear, size: 16, color: Colors.grey))],
                          ]),
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(onTap: () => _choisirDate(context, false),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: _dateFin != null ? kNuit : Colors.grey),
                            const SizedBox(width: 8),
                            Text(_dateFin != null ? 'A : ${_formatDate(_dateFin!)}' : 'Date de fin',
                                style: TextStyle(fontSize: 13, color: _dateFin != null ? kNuit : Colors.grey)),
                            if (_dateFin != null) ...[const Spacer(),
                              GestureDetector(onTap: () => setState(() => _dateFin = null),
                                  child: const Icon(Icons.clear, size: 16, color: Colors.grey))],
                          ]),
                        ),
                      )),
                    ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            _StatCard('Total envoye', 'FCFA 37 500', kRouge),
            const SizedBox(width: 10),
            _StatCard('Total recu', 'FCFA 70 000', kVert),
          ]),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, color: Colors.grey.shade300, size: 48),
                  const SizedBox(height: 12),
                  const Text('Aucun resultat trouve', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextButton(onPressed: _reinitialiser,
                      child: const Text('Reinitialiser les filtres', style: TextStyle(color: kOrange))),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final t = _filtered[i];
                    return _TxItem(initiales: t['initiales'], nom: t['nom'],
                        operateur: t['op'], date: t['date'],
                        montant: t['montant'], isOut: t['out'], colorIndex: t['ci'] ?? 0);
                  }),
        ),
      ]),
    );
  }
}

class _FiltreBtn extends StatelessWidget {
  final String label, value, current;
  final Function(String) onTap;
  const _FiltreBtn(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? kNuit : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey)),
      ),
    );
  }
}

class _TriBtn extends StatelessWidget {
  final String label, value, current;
  final Function(String) onTap;
  const _TriBtn(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? kOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? kOrange : Colors.grey.shade300)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, valeur;
  final Color couleur;
  const _StatCard(this.label, this.valeur, this.couleur);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(valeur, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: couleur)),
        ]),
      ),
    );
  }
}

// ─── ÉCRAN PROFIL ─────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)])),
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
              _ProfilStat('FCFA 284K', 'Total envoye'),
              Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _ProfilStat('${ContactsManager.contacts.length}', 'Contacts'),
            ]),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Informations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
            const SizedBox(height: 10),
            _ProfilRow(Icons.phone_outlined, 'Telephone', '+228 90 12 34 56'),
            _ProfilRow(Icons.location_on_outlined, 'Pays', 'Togo / Pays-Bas'),
            _ProfilRow(Icons.verified_outlined, 'Compte verifie', 'Oui', valueColor: kVert),
            _ProfilRow(Icons.account_balance_wallet_outlined, 'Mode', 'Local FCFA'),
            _ProfilRow(Icons.euro_outlined, 'Taux EUR/FCFA', '1 EUR = ${TauxChangeService.tauxEuroFcfa.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 18),
            const Text('Parametres', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
            const SizedBox(height: 10),
            _ProfilRow(Icons.notifications_outlined, 'Notifications', 'Activees'),
            _ProfilRow(Icons.language_outlined, 'Langue', 'Francais'),
            _ProfilRow(Icons.fingerprint_outlined, 'Securite', 'Biometrie'),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  const Icon(Icons.people_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Contacts favoris', style: TextStyle(fontSize: 14))),
                  Text('${ContactsManager.contacts.length} contacts',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Se deconnecter', style: TextStyle(color: Colors.grey, fontSize: 15)),
                )),
          ]),
        ),
      ]),
    );
  }
}

class _ProfilStat extends StatelessWidget {
  final String valeur, label;
  const _ProfilStat(this.valeur, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]);
  }
}

class _ProfilRow extends StatelessWidget {
  final IconData icon;
  final String label, valeur;
  final Color? valueColor;
  const _ProfilRow(this.icon, this.label, this.valeur, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(valeur, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? Colors.grey)),
      ]),
    );
  }
}

// ─── ÉCRAN CONNEXION ──────────────────────────────────────
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
      backgroundColor: kFond,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Row(children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: kNuit, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.arrow_upward, color: kOrange, size: 26)),
              const SizedBox(width: 14),
              const Text('haya', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: kNuit, letterSpacing: -1)),
            ]),
            const SizedBox(height: 10),
            const Text("Envoie. C'est parti.", style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isLogin = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: _isLogin ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Text('Connexion', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _isLogin ? kNuit : Colors.grey)),
                  ),
                )),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isLogin = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: !_isLogin ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Text('Inscription', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: !_isLogin ? kNuit : Colors.grey)),
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Numero de telephone', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('+228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey))),
                Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(hintText: 'XX XX XX XX', border: InputBorder.none))),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('Mot de passe', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: '........', border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false),
                  style: ElevatedButton.styleFrom(backgroundColor: kNuit,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_isLogin ? 'Se connecter' : 'Creer mon compte',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                )),
            const SizedBox(height: 18),
            Center(child: Text(
              _isLogin ? "Pas encore de compte ? Inscris-toi" : "Deja un compte ? Connecte-toi",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            )),
          ]),
        ),
      ),
    );
  }
}
