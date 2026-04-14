import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ─── ÉCRAN PRINCIPAL AVEC NAVIGATION ─────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SendScreen(),
    HistoryScreen(),
    ProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activité'),
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
  bool _soldeVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('haya', style: TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w500, letterSpacing: -0.5)),
                      ],
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: kOrange.withOpacity(0.3),
                      child: const Text('KA', style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Bonjour, Koffi 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white54, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Connectez votre compte pour voir votre solde',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Text('Togo · Mode local',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                      color: Colors.white12, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactAction(icon: Icons.arrow_outward, label: 'Envoyer',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SendScreen()))),
                      _VertDivider(),
                      _CompactAction(icon: Icons.arrow_downward, label: 'Recevoir',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ReceiveScreen()))),
                      _VertDivider(),
                      _CompactAction(icon: Icons.history, label: 'Historique',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                      _VertDivider(),
                      _CompactAction(icon: Icons.person_outline, label: 'Profil',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transactions récentes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  child: const Text('Voir tout',
                      style: TextStyle(fontSize: 13, color: kOrange, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _TxItem(initiales: 'AK', nom: 'Ama Kpodo', operateur: 'Tmoney',
                    date: 'Auj. 10:24', montant: '−5 000', isOut: true, colorIndex: 0),
                _TxItem(initiales: 'YB', nom: 'Yawa Bossa', operateur: 'Flooz',
                    date: 'Hier · 14:05', montant: '+20 000', isOut: false, colorIndex: 1),
                _TxItem(initiales: 'KD', nom: 'Kofi Dossou', operateur: 'Tmoney',
                    date: '5 avr.', montant: '−10 000', isOut: true, colorIndex: 4),
                _TxItem(initiales: 'EK', nom: 'Edem Klu', operateur: 'Flooz',
                    date: '3 avr.', montant: '+50 000', isOut: false, colorIndex: 5),
                _TxItem(initiales: 'NA', nom: 'Nana Agbeko', operateur: 'Tmoney',
                    date: '1 avr.', montant: '−7 500', isOut: true, colorIndex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white24);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kOrange, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
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
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: bgColor,
              child: Text(initiales, style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: textColor))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isTmoney ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(operateur, style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isTmoney ? kNuit : const Color(0xFF854F0B))),
                ),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ]),
          ),
          Text(montant, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
              color: isOut ? kRouge : kVert)),
        ],
      ),
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

  String get _numeroCourant =>
      _operateurSelectionne == 'tmoney' ? _numeroTmoney : _numeroFlooz;
  String get _nomOperateur =>
      _operateurSelectionne == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';

  void _copierNumero(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '+228 $_numeroCourant'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Numéro copié !'),
      backgroundColor: kVert,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _partagerNumero(BuildContext context) {
    final message = 'Envoie-moi de l\'argent sur Haya !\n\nNom : $_nomUtilisateur\nNuméro $_nomOperateur : +228 $_numeroCourant\n\nTélécharge Haya : https://play.google.com/store/apps/details?id=com.example.haya';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Message de partage copié ! Colle-le dans WhatsApp.'),
      backgroundColor: kNuit,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recevoir de l\'argent',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
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
              Text('+228 $_numeroCourant', style: const TextStyle(fontSize: 26,
                  fontWeight: FontWeight.w600, letterSpacing: 1, color: kNuit)),
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
              Expanded(child: Text('Montre ce QR code ou partage ton numéro pour recevoir de l\'argent directement sur ton compte $_nomOperateur.',
                  style: const TextStyle(fontSize: 13, color: kVert))),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _copierNumero(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copier le numéro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(backgroundColor: kNuit, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _partagerNumero(context),
                icon: const Icon(Icons.share, size: 18, color: kOrange),
                label: const Text('Partager via WhatsApp / SMS',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kOrange)),
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
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                  color: isActive ? couleur : Colors.grey)),
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
  const SendScreen({super.key});
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _operateur = '';

  int get _montant => int.tryParse(_amountCtrl.text) ?? 0;
  int get _frais => _montant > 0 ? (_montant * 0.025).round() : 0;
  int get _total => _montant + _frais;

  bool get _peutEnvoyer =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
      (_operateur == 'tmoney' || _operateur == 'flooz') &&
      _montant > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Envoyer de l\'argent',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const Text('Numéro du bénéficiaire', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('🇹🇬 +228', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey))),
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
                Text('Numéro non reconnu', style: TextStyle(color: kRouge, fontSize: 13)),
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
          _FeeRow(label: 'Total débité',
              valeur: 'FCFA ${_total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}'),
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
                  montant: _montant,
                  reseau: PayGateService.convertirOperateur(_operateur),
                  reference: ref,
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
                style: TextStyle(color: _peutEnvoyer ? Colors.white : Colors.grey,
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(child: Text('Sécurisé par PayGate Global · Togo',
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
      decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bordure)),
      child: Row(children: [
        Container(width: 34, height: 34,
            decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(logo, style: const TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.w500)))),
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
class SuccessScreen extends StatelessWidget {
  final int montant, frais;
  final String numero, operateur;
  const SuccessScreen({super.key, required this.montant, required this.numero,
      required this.operateur, required this.frais});

  @override
  Widget build(BuildContext context) {
    final ref = 'TG-${(10000 + DateTime.now().millisecond * 9).toString()}';
    return Scaffold(
      backgroundColor: kFond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 72, height: 72,
                decoration: const BoxDecoration(color: Color(0xFFE7F6EF), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: kVert, size: 40)),
            const SizedBox(height: 18),
            const Text('Transfert envoyé !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('FCFA $montant', style: const TextStyle(fontSize: 34,
                fontWeight: FontWeight.w500, letterSpacing: -1, color: kNuit)),
            const SizedBox(height: 6),
            Text('Vers $numero · $operateur', style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _ReceiptRow('Opérateur', operateur),
                _ReceiptRow('Numéro', '+228 $numero'),
                _ReceiptRow('Référence', '#$ref'),
                _ReceiptRow('Frais', 'FCFA $frais'),
                _ReceiptRow('Statut', 'Complété ✓', valueColor: kVert),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: kNuit,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Retour à l\'accueil',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                )),
          ]),
        ),
      ),
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
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black)),
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
    {'initiales': 'AK', 'nom': 'Ama Kpodo', 'op': 'Tmoney', 'date': 'Auj. 10:24', 'montant': '−5 000', 'montantVal': 5000, 'dateVal': DateTime(2026, 4, 14), 'out': true, 'ci': 0},
    {'initiales': 'YB', 'nom': 'Yawa Bossa', 'op': 'Flooz', 'date': 'Hier · 14:05', 'montant': '+20 000', 'montantVal': 20000, 'dateVal': DateTime(2026, 4, 13), 'out': false, 'ci': 1},
    {'initiales': 'KD', 'nom': 'Kofi Dossou', 'op': 'Tmoney', 'date': '5 avr.', 'montant': '−10 000', 'montantVal': 10000, 'dateVal': DateTime(2026, 4, 5), 'out': true, 'ci': 4},
    {'initiales': 'EK', 'nom': 'Edem Klu', 'op': 'Flooz', 'date': '3 avr.', 'montant': '+50 000', 'montantVal': 50000, 'dateVal': DateTime(2026, 4, 3), 'out': false, 'ci': 5},
    {'initiales': 'NA', 'nom': 'Nana Agbeko', 'op': 'Tmoney', 'date': '1 avr.', 'montant': '−7 500', 'montantVal': 7500, 'dateVal': DateTime(2026, 4, 1), 'out': true, 'ci': 2},
    {'initiales': 'PK', 'nom': 'Papa Kojo', 'op': 'Flooz', 'date': '29 mars', 'montant': '−15 000', 'montantVal': 15000, 'dateVal': DateTime(2026, 3, 29), 'out': true, 'ci': 3},
  ];

  List<Map<String, dynamic>> get _filtered {
    var liste = _transactions.where((t) {
      // Filtre opérateur/type
      if (_filtre == 'tmoney' && t['op'] != 'Tmoney') return false;
      if (_filtre == 'flooz' && t['op'] != 'Flooz') return false;
      if (_filtre == 'envois' && t['out'] != true) return false;
      if (_filtre == 'recus' && t['out'] != false) return false;
      // Filtre par nom
      if (_rechercheNom.isNotEmpty) {
        if (!t['nom'].toString().toLowerCase().contains(_rechercheNom.toLowerCase())) return false;
      }
      // Filtre par montant exact
      if (_rechercheMontant.isNotEmpty) {
        final montantRecherche = int.tryParse(_rechercheMontant.replaceAll(' ', ''));
        if (montantRecherche != null && t['montantVal'] != montantRecherche) return false;
      }
      // Filtre par date
      if (_dateDebut != null) {
        final dateT = t['dateVal'] as DateTime;
        if (dateT.isBefore(_dateDebut!)) return false;
      }
      if (_dateFin != null) {
        final dateT = t['dateVal'] as DateTime;
        if (dateT.isAfter(_dateFin!)) return false;
      }
      return true;
    }).toList();

    // Tri
    if (_triPar == 'nom') {
      liste.sort((a, b) => a['nom'].toString().compareTo(b['nom'].toString()));
    } else if (_triPar == 'montant') {
      liste.sort((a, b) => (b['montantVal'] as int).compareTo(a['montantVal'] as int));
    } else {
      liste.sort((a, b) => (b['dateVal'] as DateTime).compareTo(a['dateVal'] as DateTime));
    }
    return liste;
  }

  void _choisirDate(BuildContext context, bool isDebut) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kNuit, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        if (isDebut) _dateDebut = date;
        else _dateFin = date;
      });
    }
  }

  void _reinitialiser() {
    setState(() {
      _rechercheNom = '';
      _rechercheMontant = '';
      _dateDebut = null;
      _dateFin = null;
      _nomCtrl.clear();
      _montantCtrl.clear();
    });
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasFilters = _rechercheNom.isNotEmpty || _rechercheMontant.isNotEmpty || _dateDebut != null || _dateFin != null;

    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: kNuit, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Activité', style: TextStyle(color: Colors.white,
            fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          if (hasFilters)
            TextButton.icon(
              onPressed: _reinitialiser,
              icon: const Icon(Icons.refresh, color: kOrange, size: 16),
              label: const Text('Réinitialiser', style: TextStyle(color: kOrange, fontSize: 12)),
            ),
        ],
      ),
      body: Column(children: [
        // Filtres opérateur
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FiltreBtn('Tout', 'tout', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Tmoney', 'tmoney', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Flooz', 'flooz', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Envois', 'envois', _filtre, (v) => setState(() => _filtre = v)),
              _FiltreBtn('Reçus', 'recus', _filtre, (v) => setState(() => _filtre = v)),
            ]),
          ),
        ),
        // Trier par
        Container(
          color: kFond,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            const Text('Trier par :', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            _TriBtn('Date', 'date', _triPar, (v) => setState(() => _triPar = v)),
            const SizedBox(width: 6),
            _TriBtn('Montant', 'montant', _triPar, (v) => setState(() => _triPar = v)),
            const SizedBox(width: 6),
            _TriBtn('Nom', 'nom', _triPar, (v) => setState(() => _triPar = v)),
            const Spacer(),
            Text('${_filtered.length} résultat(s)',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        // Zone de recherche dynamique selon le tri
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _triPar == 'nom'
              ? TextField(
                  controller: _nomCtrl,
                  onChanged: (v) => setState(() => _rechercheNom = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.person_search, color: Colors.grey, size: 20),
                    suffixIcon: _rechercheNom.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                            onPressed: () => setState(() { _rechercheNom = ''; _nomCtrl.clear(); }))
                        : null,
                    filled: true, fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                )
              : _triPar == 'montant'
                  ? TextField(
                      controller: _montantCtrl,
                      onChanged: (v) => setState(() => _rechercheMontant = v),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Montant exact en FCFA (ex: 5000)',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.grey, size: 20),
                        suffixIcon: _rechercheMontant.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                onPressed: () => setState(() { _rechercheMontant = ''; _montantCtrl.clear(); }))
                            : null,
                        filled: true, fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    )
                  : Column(children: [
                      // Date De
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _choisirDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_today_outlined, size: 16,
                                    color: _dateDebut != null ? kNuit : Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _dateDebut != null ? 'De : ${_formatDate(_dateDebut!)}' : 'Date de début',
                                  style: TextStyle(fontSize: 13,
                                      color: _dateDebut != null ? kNuit : Colors.grey),
                                ),
                                if (_dateDebut != null) ...[
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(() => _dateDebut = null),
                                    child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                  ),
                                ],
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _choisirDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_today_outlined, size: 16,
                                    color: _dateFin != null ? kNuit : Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _dateFin != null ? 'À : ${_formatDate(_dateFin!)}' : 'Date de fin',
                                  style: TextStyle(fontSize: 13,
                                      color: _dateFin != null ? kNuit : Colors.grey),
                                ),
                                if (_dateFin != null) ...[
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(() => _dateFin = null),
                                    child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                  ),
                                ],
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ]),
        ),
        // Stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            _StatCard('Total envoyé', 'FCFA 37 500', kRouge),
            const SizedBox(width: 10),
            _StatCard('Total reçu', 'FCFA 70 000', kVert),
          ]),
        ),
        // Liste
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 12),
                    const Text('Aucun résultat trouvé',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextButton(onPressed: _reinitialiser,
                        child: const Text('Réinitialiser les filtres', style: TextStyle(color: kOrange))),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final t = _filtered[i];
                    return _TxItem(initiales: t['initiales'], nom: t['nom'],
                        operateur: t['op'], date: t['date'],
                        montant: t['montant'], isOut: t['out'], colorIndex: t['ci'] ?? 0);
                  },
                ),
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
        decoration: BoxDecoration(
          color: isActive ? kNuit : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
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
                child: const Text('KA', style: TextStyle(color: Colors.white,
                    fontSize: 24, fontWeight: FontWeight.w600))),
            const SizedBox(height: 14),
            const Text('Koffi Ameko', style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            const Text('koffi.ameko@gmail.com',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ProfilStat('47', 'Transferts'),
              Container(width: 1, height: 30, color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 20)),
              _ProfilStat('FCFA 284K', 'Total envoyé'),
              Container(width: 1, height: 30, color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 20)),
              _ProfilStat('12', 'Contacts'),
            ]),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Informations', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w500, color: Colors.grey)),
            const SizedBox(height: 10),
            _ProfilRow(Icons.phone_outlined, 'Téléphone', '+228 90 12 34 56'),
            _ProfilRow(Icons.location_on_outlined, 'Pays', 'Togo / Pays-Bas'),
            _ProfilRow(Icons.verified_outlined, 'Compte vérifié', 'Oui', valueColor: kVert),
            _ProfilRow(Icons.account_balance_wallet_outlined, 'Mode', 'Local FCFA'),
            const SizedBox(height: 18),
            const Text('Paramètres', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w500, color: Colors.grey)),
            const SizedBox(height: 10),
            _ProfilRow(Icons.notifications_outlined, 'Notifications', 'Activées'),
            _ProfilRow(Icons.language_outlined, 'Langue', 'Français'),
            _ProfilRow(Icons.fingerprint_outlined, 'Sécurité', 'Biométrie'),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Se déconnecter', style: TextStyle(color: Colors.grey, fontSize: 15)),
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
        Text(valeur, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.grey)),
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
              const Text('haya', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500,
                  color: kNuit, letterSpacing: -1)),
            ]),
            const SizedBox(height: 10),
            const Text('Envoie. C\'est parti.', style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isLogin = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isLogin ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('Connexion', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: _isLogin ? kNuit : Colors.grey)),
                  ),
                )),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isLogin = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isLogin ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('Inscription', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: !_isLogin ? kNuit : Colors.grey)),
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Numéro de téléphone', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('🇹🇬 +228', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w500, color: Colors.grey))),
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
              child: TextField(controller: _passCtrl, obscureText: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: '••••••••', border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false),
                  style: ElevatedButton.styleFrom(backgroundColor: kNuit,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_isLogin ? 'Se connecter' : 'Créer mon compte',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                )),
            const SizedBox(height: 18),
            Center(child: Text(
              _isLogin ? 'Pas encore de compte ? Inscris-toi' : 'Déjà un compte ? Connecte-toi',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            )),
          ]),
        ),
      ),
    );
  }
}
