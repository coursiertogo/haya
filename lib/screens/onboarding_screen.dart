import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../services/managers.dart';
import 'pin_screen.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _etape = 1;
  bool _chargement = false;
  String _erreur = '';

  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpEnvoye = false;
  String _telSauvegarde = '';

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ─── OTP ──────────────────────────────────────────────

  Future<void> _envoyerOTP() async {
    final tel = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (tel.length != 8) {
      setState(() => _erreur = 'Entrez un numéro à 8 chiffres.');
      return;
    }
    _telSauvegarde = tel;
    setState(() { _chargement = true; _erreur = ''; });
    try {
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': tel}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['dev_otp'] != null) {
        _otpCtrl.text = data['dev_otp'];
      }
    } catch (_) {}
    if (mounted) setState(() { _chargement = false; _otpEnvoye = true; });
  }

  Future<void> _verifierOTP() async {
    if (_otpCtrl.text.length < 6) {
      setState(() => _erreur = 'Entrez le code à 6 chiffres.');
      return;
    }
    setState(() { _chargement = true; _erreur = ''; });
    try {
      final tel = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/verifier-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': tel, 'otp': _otpCtrl.text}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['nouveau'] == false) {
          await _connecterUtilisateur(data['utilisateur']);
        } else {
          _allerVersPIN();
        }
      } else {
        setState(() => _erreur = data['message'] ?? 'Code incorrect.');
      }
    } catch (_) {
      _allerVersPIN();
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  // ─── NAVIGATION ───────────────────────────────────────

  void _allerVersPIN() {
    UserManager.telephone = _telSauvegarde;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          titre: 'Ton PIN de securite',
          sousTitre:
              'Ce code securise chaque transfert.\nChoisis 6 chiffres faciles a retenir.',
          modeDefinition: true,
          onSuccess: (pin) async => await _creerCompte(pin),
        ),
      ),
    );
  }

  Future<void> _connecterUtilisateur(Map<String, dynamic> u) async {
    UserManager.prenom = u['prenom'] ?? '';
    UserManager.nom = u['nom'] ?? '';
    final telFromDb = u['telephone']?.toString() ?? '';
    UserManager.telephone = telFromDb.isNotEmpty ? telFromDb : _telSauvegarde;
    UserManager.id = u['id'] ?? 0;
    HayaApiService.utilisateurId = UserManager.id;
    await UserManager.sauvegarder();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  Future<void> _creerCompte(String pin) async {
    await PinManager.definirPin(pin);
    try {
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/inscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prenom': _prenomCtrl.text.trim(),
          'nom': _nomCtrl.text.trim(),
          'telephone': _telSauvegarde,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _connecterUtilisateur(data['utilisateur']);
        return;
      }
    } catch (_) {}

    // Fallback local (sandbox / hors ligne)
    UserManager.prenom = _prenomCtrl.text.trim();
    UserManager.nom = _nomCtrl.text.trim();
    UserManager.telephone = _telSauvegarde;
    UserManager.id = 1;
    HayaApiService.utilisateurId = 1;
    await UserManager.sauvegarder();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  // ─── BUILD ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNuit,
      body: SafeArea(
        child: _etape == 1 ? _buildBienvenue() : _buildFormulaire(),
      ),
    );
  }

  // ÉTAPE 1 — Bienvenue
  Widget _buildBienvenue() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(children: [
        const Spacer(flex: 2),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
              color: kOrange, borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('haya',
            style: TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w700,
                letterSpacing: -2)),
        const SizedBox(height: 6),
        Text("Envoie. C'est parti.",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 16)),
        const Spacer(flex: 2),
        _FeatureRow(
          icon: Icons.swap_horiz_rounded,
          titre: 'Cross-operateur',
          sous: 'Envoie vers Tmoney ou Flooz, peu importe ton operateur.',
        ),
        const SizedBox(height: 20),
        _FeatureRow(
          icon: Icons.link_rounded,
          titre: 'Demande de paiement',
          sous: 'Partage un lien, le destinataire paie en 1 clic.',
        ),
        const SizedBox(height: 20),
        _FeatureRow(
          icon: Icons.bolt_rounded,
          titre: 'Simple et rapide',
          sous: 'Un numero, un montant. C\'est tout.',
        ),
        const Spacer(flex: 3),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () => setState(() => _etape = 2),
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: const Text('Commencer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Togo · haya.flexix.nl',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
      ]),
    );
  }

  // ÉTAPES 2 & 3 — Formulaire
  Widget _buildFormulaire() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_etape == 2) {
                setState(() => _etape = 1);
              } else {
                setState(() {
                  _etape = 2;
                  _otpEnvoye = false;
                  _otpCtrl.clear();
                  _erreur = '';
                });
              }
            },
          ),
          const Spacer(),
          Row(children: List.generate(2, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i + 2 == _etape ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                    color: i + 2 == _etape
                        ? kOrange
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4)),
              ))),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: _etape == 2 ? _buildNom() : _buildTelephone(),
        ),
      ),
    ]);
  }

  // ÉTAPE 2 — Nom
  Widget _buildNom() {
    final peut = _prenomCtrl.text.trim().isNotEmpty &&
        _nomCtrl.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Comment tu t'appelles ?",
          style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(
          'Ces informations apparaîtront sur tes demandes de paiement.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
      const SizedBox(height: 40),
      _Champ(
          label: 'Prénom',
          hint: 'Koami',
          controller: _prenomCtrl,
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 18),
      _Champ(
          label: 'Nom',
          hint: 'Azanleko',
          controller: _nomCtrl,
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 48),
      SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: peut ? () => setState(() => _etape = 3) : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: const Text('Continuer',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  // ÉTAPE 3 — Téléphone + OTP
  Widget _buildTelephone() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          _otpEnvoye
              ? 'Vérifie ton numéro'
              : 'Ton numéro de téléphone',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(
          _otpEnvoye
              ? 'Entre le code à 6 chiffres envoyé au\n+228 ${_phoneCtrl.text}'
              : 'Tu recevras un code SMS pour confirmer ton numéro.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
      const SizedBox(height: 40),

      if (!_otpEnvoye) ...[
        Text('Numéro',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24)),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('+228',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 17,
                      fontWeight: FontWeight.w500)),
            ),
            Container(width: 1, height: 32, color: Colors.white24),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 8,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                    hintText: 'XX XX XX XX',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 17)),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
        ),
      ] else ...[
        Text('Code SMS',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24)),
          child: TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 12),
            decoration: const InputDecoration(
                hintText: '······',
                hintStyle:
                    TextStyle(color: Colors.white30, letterSpacing: 8),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 18)),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: _chargement
                ? null
                : () => setState(() {
                      _otpEnvoye = false;
                      _otpCtrl.clear();
                      _erreur = '';
                    }),
            child: Text('Changer de numéro',
                style: TextStyle(
                    color: kOrange.withValues(alpha: 0.8), fontSize: 13)),
          ),
        ),
      ],

      if (_erreur.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kRouge.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kRouge.withValues(alpha: 0.35))),
          child: Row(children: [
            const Icon(Icons.error_outline, color: kRouge, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(_erreur,
                    style:
                        const TextStyle(color: kRouge, fontSize: 13))),
          ]),
        ),
      ],

      const SizedBox(height: 48),
      SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _chargement
              ? null
              : (_otpEnvoye ? _verifierOTP : _envoyerOTP),
          style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: _chargement
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  _otpEnvoye
                      ? 'Vérifier le code'
                      : 'Envoyer le code SMS',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

// ─── WIDGETS INTERNES ────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String titre, sous;
  const _FeatureRow(
      {required this.icon, required this.titre, required this.sous});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: kOrange, size: 23),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(sous,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13)),
              ]),
        ),
      ]);
}

class _Champ extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final Function(String) onChanged;
  const _Champ(
      {required this.label,
      required this.hint,
      required this.controller,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24)),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16)),
              onChanged: onChanged,
            ),
          ),
        ],
      );
}
