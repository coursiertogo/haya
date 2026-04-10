import 'package:flutter/material.dart';

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
      home: const HomeScreen(),
    );
  }
}

// ─── COULEURS HAYA ───────────────────────────────────────
const kNuit = Color(0xFF0D0D2B);
const kOrange = Color(0xFFF97316);
const kVert = Color(0xFF1D9E75);
const kFond = Color(0xFFF5F4FF);
const kRouge = Color(0xFFE24B4A);

// ─── PRÉFIXES OPÉRATEURS TOGO ────────────────────────────
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

// ─── ÉCRAN ACCUEIL ───────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      body: Column(
        children: [
          // Header
          Container(
            color: kNuit,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kOrange,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'haya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: const Text(
                        'KA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Solde disponible',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FCFA 125 000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'Togo · Mode local',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Actions rapides
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.arrow_outward,
                  label: 'Envoyer',
                  color: const Color(0xFFEEEDFE),
                  iconColor: kNuit,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SendScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _ActionBtn(
                  icon: Icons.arrow_downward,
                  label: 'Recevoir',
                  color: const Color(0xFFD7F3EA),
                  iconColor: kVert,
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _ActionBtn(
                  icon: Icons.history,
                  label: 'Historique',
                  color: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _ActionBtn(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  color: const Color(0xFFF1EFE8),
                  iconColor: Colors.grey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
          ),

          // Transactions récentes
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transactions récentes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _TxItem(
                  initiales: 'AK',
                  nom: 'Ama Kpodo',
                  operateur: 'Tmoney',
                  date: 'Auj. 10:24',
                  montant: '−5 000',
                  isOut: true,
                ),
                _TxItem(
                  initiales: 'YB',
                  nom: 'Yawa Bossa',
                  operateur: 'Flooz',
                  date: 'Hier · 14:05',
                  montant: '+20 000',
                  isOut: false,
                ),
                _TxItem(
                  initiales: 'KD',
                  nom: 'Kofi Dossou',
                  operateur: 'Tmoney',
                  date: '5 avr.',
                  montant: '−10 000',
                  isOut: true,
                ),
                _TxItem(
                  initiales: 'EK',
                  nom: 'Edem Klu',
                  operateur: 'Flooz',
                  date: '3 avr.',
                  montant: '+50 000',
                  isOut: false,
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kOrange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            label: 'Envoyer',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activité'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─── WIDGET ACTION BUTTON ────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET TRANSACTION ──────────────────────────────────
class _TxItem extends StatelessWidget {
  final String initiales, nom, operateur, date, montant;
  final bool isOut;
  const _TxItem({
    required this.initiales,
    required this.nom,
    required this.operateur,
    required this.date,
    required this.montant,
    required this.isOut,
  });

  @override
  Widget build(BuildContext context) {
    final isTmoney = operateur == 'Tmoney';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isTmoney
                ? const Color(0xFFEEEDFE)
                : const Color(0xFFFAEEDA),
            child: Text(
              initiales,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isTmoney ? kNuit : const Color(0xFF854F0B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isTmoney
                            ? const Color(0xFFEEEDFE)
                            : const Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        operateur,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: isTmoney ? kNuit : const Color(0xFF854F0B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            montant,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isOut ? kRouge : kVert,
            ),
          ),
        ],
      ),
    );
  }
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Envoyer de l\'argent',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ numéro
            const Text(
              'Numéro du bénéficiaire',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '🇹🇬 +228',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        hintText: 'XX XX XX XX',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (v) => setState(() {
                        _operateur = detectOperateur(v);
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Détection opérateur
            if (_operateur == 'tmoney')
              _OperateurBox(
                nom: 'Mixx by Yas (Tmoney)',
                sub: 'Yas Togo',
                couleur: const Color(0xFFEEEDFE),
                bordure: const Color(0xFFAFA9EC),
                textColor: kNuit,
                logo: 'M',
              ),
            if (_operateur == 'flooz')
              _OperateurBox(
                nom: 'Flooz (Moov Africa)',
                sub: 'Moov Africa Togo',
                couleur: const Color(0xFFFFF5EA),
                bordure: const Color(0xFFFAC775),
                textColor: const Color(0xFF854F0B),
                logo: 'F',
              ),
            if (_operateur == 'inconnu')
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF0F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF7C1C1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: kRouge, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Numéro non reconnu',
                      style: TextStyle(color: kRouge, fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Montant
            const Text(
              'Montant (FCFA)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Montants rapides
            Wrap(
              spacing: 6,
              children: [1000, 2000, 5000, 10000, 25000]
                  .map(
                    (v) => GestureDetector(
                      onTap: () => setState(() {
                        _amountCtrl.text = v.toString();
                      }),
                      child: Chip(
                        label: Text(
                          '${v ~/ 1000 >= 1 ? v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ') : v}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 14),

            // Frais
            _FeeRow(
              label: 'Frais PayGate (2.5%)',
              valeur:
                  'FCFA ${_frais.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
            ),
            const SizedBox(height: 4),
            _FeeRow(
              label: 'Total débité',
              valeur:
                  'FCFA ${_total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
            ),

            const SizedBox(height: 20),

            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _peutEnvoyer
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SuccessScreen(
                              montant: _montant,
                              numero: _phoneCtrl.text,
                              operateur: _operateur == 'tmoney'
                                  ? 'Mixx by Yas (Tmoney)'
                                  : 'Flooz (Moov Africa)',
                              frais: _frais,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNuit,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _peutEnvoyer
                      ? 'Envoyer via ${_operateur == 'tmoney' ? 'Tmoney' : 'Flooz'}'
                      : 'Confirmer le transfert',
                  style: TextStyle(
                    color: _peutEnvoyer ? Colors.white : Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Sécurisé par PayGate Global · Togo',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGET OPÉRATEUR ────────────────────────────────────
class _OperateurBox extends StatelessWidget {
  final String nom, sub, logo;
  final Color couleur, bordure, textColor;
  const _OperateurBox({
    required this.nom,
    required this.sub,
    required this.logo,
    required this.couleur,
    required this.bordure,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bordure),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                logo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nom,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── WIDGET FRAIS ────────────────────────────────────────
class _FeeRow extends StatelessWidget {
  final String label, valeur;
  const _FeeRow({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            valeur,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── ÉCRAN SUCCÈS ─────────────────────────────────────────
class SuccessScreen extends StatelessWidget {
  final int montant, frais;
  final String numero, operateur;
  const SuccessScreen({
    super.key,
    required this.montant,
    required this.numero,
    required this.operateur,
    required this.frais,
  });

  @override
  Widget build(BuildContext context) {
    final ref = 'TG-${(10000 + DateTime.now().millisecond * 9).toString()}';
    return Scaffold(
      backgroundColor: kFond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F6EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: kVert,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transfert envoyé !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'FCFA $montant',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1,
                  color: kNuit,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vers $numero · $operateur',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _ReceiptRow('Opérateur', operateur),
                    _ReceiptRow('Numéro', '+228 $numero'),
                    _ReceiptRow('Référence', '#$ref'),
                    _ReceiptRow('Frais', 'FCFA $frais'),
                    _ReceiptRow('Statut', 'Complété ✓', valueColor: kVert),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNuit,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
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

  final List<Map<String, dynamic>> _transactions = [
    {
      'initiales': 'AK',
      'nom': 'Ama Kpodo',
      'op': 'Tmoney',
      'date': 'Auj. 10:24',
      'montant': '−5 000',
      'out': true,
    },
    {
      'initiales': 'YB',
      'nom': 'Yawa Bossa',
      'op': 'Flooz',
      'date': 'Hier · 14:05',
      'montant': '+20 000',
      'out': false,
    },
    {
      'initiales': 'KD',
      'nom': 'Kofi Dossou',
      'op': 'Tmoney',
      'date': '5 avr.',
      'montant': '−10 000',
      'out': true,
    },
    {
      'initiales': 'EK',
      'nom': 'Edem Klu',
      'op': 'Flooz',
      'date': '3 avr.',
      'montant': '+50 000',
      'out': false,
    },
    {
      'initiales': 'NA',
      'nom': 'Nana Agbeko',
      'op': 'Tmoney',
      'date': '1 avr.',
      'montant': '−7 500',
      'out': true,
    },
    {
      'initiales': 'PK',
      'nom': 'Papa Kojo',
      'op': 'Flooz',
      'date': '29 mars',
      'montant': '−15 000',
      'out': true,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_filtre == 'tout') return _transactions;
    if (_filtre == 'tmoney')
      return _transactions.where((t) => t['op'] == 'Tmoney').toList();
    if (_filtre == 'flooz')
      return _transactions.where((t) => t['op'] == 'Flooz').toList();
    if (_filtre == 'envois')
      return _transactions.where((t) => t['out'] == true).toList();
    if (_filtre == 'recus')
      return _transactions.where((t) => t['out'] == false).toList();
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historique',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltreBtn(
                    'Tout',
                    'tout',
                    _filtre,
                    (v) => setState(() => _filtre = v),
                  ),
                  _FiltreBtn(
                    'Tmoney',
                    'tmoney',
                    _filtre,
                    (v) => setState(() => _filtre = v),
                  ),
                  _FiltreBtn(
                    'Flooz',
                    'flooz',
                    _filtre,
                    (v) => setState(() => _filtre = v),
                  ),
                  _FiltreBtn(
                    'Envois',
                    'envois',
                    _filtre,
                    (v) => setState(() => _filtre = v),
                  ),
                  _FiltreBtn(
                    'Reçus',
                    'recus',
                    _filtre,
                    (v) => setState(() => _filtre = v),
                  ),
                ],
              ),
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard('Total envoyé', 'FCFA 37 500', kRouge),
                const SizedBox(width: 10),
                _StatCard('Total reçu', 'FCFA 70 000', kVert),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final t = _filtered[i];
                return _TxItem(
                  initiales: t['initiales'],
                  nom: t['nom'],
                  operateur: t['op'],
                  date: t['date'],
                  montant: t['montant'],
                  isOut: t['out'],
                );
              },
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? kNuit : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: couleur,
              ),
            ),
          ],
        ),
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
      body: Column(
        children: [
          Container(
            color: kNuit,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: const Text(
                    'KA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Koffi Ameko',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'koffi.ameko@gmail.com',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProfilStat('47', 'Transferts'),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _ProfilStat('FCFA 284K', 'Total envoyé'),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _ProfilStat('12', 'Contacts'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Informations',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _ProfilRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  '+228 90 12 34 56',
                ),
                _ProfilRow(Icons.location_on_outlined, 'Pays', 'Togo / France'),
                _ProfilRow(
                  Icons.verified_outlined,
                  'Compte vérifié',
                  'Oui',
                  valueColor: kVert,
                ),
                _ProfilRow(
                  Icons.account_balance_wallet_outlined,
                  'Mode',
                  'Local FCFA',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paramètres',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _ProfilRow(
                  Icons.notifications_outlined,
                  'Notifications',
                  'Activées',
                ),
                _ProfilRow(Icons.language_outlined, 'Langue', 'Français'),
                _ProfilRow(Icons.fingerprint_outlined, 'Sécurité', 'Biométrie'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilStat extends StatelessWidget {
  final String valeur, label;
  const _ProfilStat(this.valeur, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valeur,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey,
            ),
          ),
        ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kNuit,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: kOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'haya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: kNuit,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Envoie. C\'est parti.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Connexion',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _isLogin ? kNuit : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Inscription',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: !_isLogin ? kNuit : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Champs
              const Text(
                'Numéro de téléphone',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '🇹🇬 +228',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'XX XX XX XX',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Mot de passe',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (r) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNuit,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLogin ? 'Se connecter' : 'Créer mon compte',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _isLogin
                      ? 'Pas encore de compte ? Inscris-toi'
                      : 'Déjà un compte ? Connecte-toi',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
