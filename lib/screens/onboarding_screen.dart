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
  // etape: 1=bienvenue, 2=nom, 3=tel, 4=otp, 5=connexion-tel
  int _etape = 1;
  bool _chargement = false;
  String _erreur = '';
  bool _erreurConnexion = false; // numéro inconnu sur cet appareil

  final _nomCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneConnexionCtrl = TextEditingController();
  bool _otpEnvoye = false;
  String _telSauvegarde = '';

  @override
  void dispose() {
    _nomCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _phoneConnexionCtrl.dispose();
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
      if (data['dev_otp'] != null) _otpCtrl.text = data['dev_otp'];
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
        _telSauvegarde = tel;
        _allerVersPIN();
      } else {
        setState(() => _erreur = data['message'] ?? 'Code incorrect.');
      }
    } catch (_) {
      setState(() => _erreur = 'Erreur de connexion. Réessaie.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  // ─── COMMENCER — création compte ──────────────────────

  void _allerVersPIN() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          titre: 'Crée ton PIN',
          sousTitre: 'Ce code sécurise l\'accès à l\'app.\nChoisis 6 chiffres faciles à retenir.',
          modeDefinition: true,
          onSuccess: (pin) async {
            await PinManager.definirPin(pin);
            UserManager.prenom = _nomCtrl.text.trim();
            UserManager.nom = '';
            UserManager.telephone = _telSauvegarde;
            UserManager.id = 1;
            HayaApiService.utilisateurId = 1;
            await UserManager.sauvegarder();
            _inscrireBackend();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _inscrireBackend() async {
    try {
      final result = await HayaApiService.inscrireUtilisateur(
        prenom: UserManager.prenom,
        telephone: UserManager.telephone,
      );
      if (result != null) {
        UserManager.id = result['id'] ?? 1;
        HayaApiService.utilisateurId = UserManager.id;
        await UserManager.sauvegarder();
      }
    } catch (_) {}
  }

  // ─── CONNEXION — utilisateur existant ─────────────────

  void _verifierConnexion() {
    final tel = _phoneConnexionCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (tel.length != 8) {
      setState(() => _erreur = 'Entrez un numéro à 8 chiffres.');
      return;
    }
    // Vérifier si ce numéro correspond au compte local
    if (UserManager.id == 0 || UserManager.telephone != tel || !PinManager.pinDefini) {
      setState(() => _erreurConnexion = true);
      return;
    }
    // Numéro reconnu → demander le PIN
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          titre: 'Ton PIN',
          sousTitre: 'Entre ton PIN pour accéder à Haya.',
          modeDefinition: false,
          onSuccess: (_) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          ),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNuit,
      body: SafeArea(
        child: _etape == 1
            ? _buildBienvenue()
            : _etape == 5
                ? _buildConnexion()
                : _buildFormulaire(),
      ),
    );
  }

  // ─── BIENVENUE ────────────────────────────────────────
  Widget _buildBienvenue() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(children: [
        const Spacer(flex: 2),
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('haya',
            style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w700, letterSpacing: -2)),
        const SizedBox(height: 6),
        Text("Envoie. C'est parti.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 16)),
        const Spacer(flex: 2),
        _FeatureRow(icon: Icons.swap_horiz_rounded, titre: 'Cross-opérateur',
            sous: 'Envoie vers Tmoney ou Flooz, peu importe ton opérateur.'),
        const SizedBox(height: 20),
        _FeatureRow(icon: Icons.link_rounded, titre: 'Demande de paiement',
            sous: 'Partage un lien, le destinataire paie en 1 clic.'),
        const SizedBox(height: 20),
        _FeatureRow(icon: Icons.bolt_rounded, titre: 'Simple et rapide',
            sous: "Un numéro, un montant. C'est tout."),
        const Spacer(flex: 3),
        SizedBox(
          width: double.infinity, height: 58,
          child: ElevatedButton(
            onPressed: () => setState(() { _etape = 2; _erreur = ''; }),
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Commencer',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton(
            onPressed: () => setState(() { _etape = 5; _erreur = ''; _erreurConnexion = false; }),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Se connecter',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Togo · haya.flexix.nl',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
      ]),
    );
  }

  // ─── FORMULAIRE COMMENCER (étapes 2-4) ───────────────
  Widget _buildFormulaire() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() {
              if (_etape == 2) { _etape = 1; }
              else if (_etape == 3) { _etape = 2; }
              else { _etape = 3; _otpEnvoye = false; _otpCtrl.clear(); _erreur = ''; }
            }),
          ),
          const Spacer(),
          Row(children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i + 2 == _etape ? 28 : 8, height: 8,
                decoration: BoxDecoration(
                    color: i + 2 <= _etape ? kOrange : Colors.white.withValues(alpha: 0.25),
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

  // ─── ÉTAPE 2 — Nom ────────────────────────────────────
  Widget _buildNom() {
    final peut = _nomCtrl.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ton nom ou entreprise',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text('Ce nom apparaîtra sur tes demandes de paiement.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
      const SizedBox(height: 40),
      _Champ(label: 'Nom complet ou entreprise', hint: 'Koami Azanleko',
          controller: _nomCtrl, onChanged: (_) => setState(() {})),
      const SizedBox(height: 48),
      SizedBox(
        width: double.infinity, height: 58,
        child: ElevatedButton(
          onPressed: peut ? () => setState(() => _etape = 3) : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: kOrange, disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Continuer',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  // ─── ÉTAPE 3 & 4 — Téléphone + OTP ───────────────────
  Widget _buildTelephone() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_otpEnvoye ? 'Vérifie ton numéro' : 'Ton numéro de téléphone',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(
          _otpEnvoye
              ? 'Entre le code à 6 chiffres envoyé au\n+228 ${_phoneCtrl.text}'
              : 'Tu recevras un code SMS pour confirmer ton numéro.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
      const SizedBox(height: 40),
      if (!_otpEnvoye) ...[
        Text('Numéro', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24)),
          child: Row(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('+228', style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 17, fontWeight: FontWeight.w500))),
            Container(width: 1, height: 32, color: Colors.white24),
            Expanded(
              child: TextField(
                controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 8,
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                    hintText: 'XX XX XX XX', hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none, counterText: '',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17)),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
        ),
      ] else ...[
        Text('Code SMS', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24)),
          child: TextField(
            controller: _otpCtrl, keyboardType: TextInputType.number,
            maxLength: 6, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w700, letterSpacing: 12),
            decoration: const InputDecoration(
                hintText: '······', hintStyle: TextStyle(color: Colors.white30, letterSpacing: 8),
                border: InputBorder.none, counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 18)),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: _chargement ? null : () => setState(() {
              _otpEnvoye = false; _otpCtrl.clear(); _erreur = '';
            }),
            child: Text('Changer de numéro',
                style: TextStyle(color: kOrange.withValues(alpha: 0.8), fontSize: 13)),
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
            Expanded(child: Text(_erreur, style: const TextStyle(color: kRouge, fontSize: 13))),
          ]),
        ),
      ],
      const SizedBox(height: 48),
      SizedBox(
        width: double.infinity, height: 58,
        child: ElevatedButton(
          onPressed: _chargement ? null : (_otpEnvoye ? _verifierOTP : _envoyerOTP),
          style: ElevatedButton.styleFrom(
              backgroundColor: kOrange, disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _chargement
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_otpEnvoye ? 'Vérifier le code' : 'Envoyer le code SMS',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  // ─── CONNEXION ────────────────────────────────────────
  Widget _buildConnexion() {
    final tel = _phoneConnexionCtrl.text.replaceAll(RegExp(r'\D'), '');
    final peut = tel.length == 8;

    if (_erreurConnexion) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() { _erreurConnexion = false; _erreur = ''; }),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: kRouge.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kRouge.withValues(alpha: 0.3))),
            child: Column(children: [
              const Icon(Icons.error_outline, color: kRouge, size: 40),
              const SizedBox(height: 12),
              const Text('Mauvaise combinaison',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Ce numéro n\'est pas enregistré sur cet appareil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
            ]),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 58,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _erreurConnexion = false;
                _etape = 2;
                _phoneCtrl.text = _phoneConnexionCtrl.text;
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text("S'inscrire",
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton(
              onPressed: () => setState(() { _erreurConnexion = false; _phoneConnexionCtrl.clear(); }),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Réessayer',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 28),
        ]),
      );
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() { _etape = 1; _erreur = ''; }),
          ),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Connexion',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('Entre ton numéro pour accéder à ton compte.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
            const SizedBox(height: 40),
            Text('Numéro', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24)),
              child: Row(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('+228', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 17, fontWeight: FontWeight.w500))),
                Container(width: 1, height: 32, color: Colors.white24),
                Expanded(
                  child: TextField(
                    controller: _phoneConnexionCtrl, keyboardType: TextInputType.phone,
                    maxLength: 8, autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                        hintText: 'XX XX XX XX', hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none, counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17)),
                    onChanged: (_) => setState(() { _erreur = ''; }),
                  ),
                ),
              ]),
            ),
            if (_erreur.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_erreur, style: const TextStyle(color: kRouge, fontSize: 13)),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: peut ? _verifierConnexion : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange, disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Continuer',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ─── WIDGETS ─────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String titre, sous;
  const _FeatureRow({required this.icon, required this.titre, required this.sous});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: kOrange, size: 23),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(sous, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ]),
        ),
      ]);
}

class _Champ extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final Function(String) onChanged;
  const _Champ({required this.label, required this.hint,
      required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24)),
            child: TextField(
              controller: controller, autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                  hintText: hint, hintStyle: const TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
              onChanged: onChanged,
            ),
          ),
        ],
      );
}
