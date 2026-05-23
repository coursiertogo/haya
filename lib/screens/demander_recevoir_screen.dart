import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';
import '../services/taux_change_service.dart';
import 'parametres_screen.dart';
import 'demandes_screen.dart';

class DemanderRecevoirScreen extends StatefulWidget {
  const DemanderRecevoirScreen({super.key});
  @override
  State<DemanderRecevoirScreen> createState() => _DemanderRecevoirScreenState();
}

class _DemanderRecevoirScreenState extends State<DemanderRecevoirScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // ── Demander state ──
  final _montantCtrl = TextEditingController();
  final _objetCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _op = '', _opSelectionne = '', _ref = '';
  bool _demandeSauvegardee = false;

  // ── Recevoir state ──
  String _opRecevoir = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _rafraichirOperateurs();
  }

  void _rafraichirOperateurs() {
    if (NumerosManager.tmoney.isNotEmpty) {
      _phoneCtrl.text = NumerosManager.tmoney;
      _op = 'tmoney';
      _opSelectionne = 'tmoney';
      _opRecevoir = 'tmoney';
    } else if (NumerosManager.flooz.isNotEmpty) {
      _phoneCtrl.text = NumerosManager.flooz;
      _op = 'flooz';
      _opSelectionne = 'flooz';
      _opRecevoir = 'flooz';
    } else {
      _op = '';
      _opSelectionne = '';
      _opRecevoir = '';
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _montantCtrl.dispose();
    _objetCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Demander helpers ──
  int get _montant => int.tryParse(_montantCtrl.text) ?? 0;

  bool get _peut =>
      _montant > 0 &&
      _objetCtrl.text.isNotEmpty &&
      _phoneCtrl.text.length == 8 &&
      (_opSelectionne == 'tmoney' || _opSelectionne == 'flooz') &&
      (NumerosManager.tmoney.isNotEmpty || NumerosManager.flooz.isNotEmpty);

  Future<bool> _sauvegarderDemande(String ref) async {
    if (_demandeSauvegardee) return true;
    _demandeSauvegardee = true;
    if (UserManager.id <= 1 || HayaApiService.token.isEmpty) {
      final result = await HayaApiService.inscrireUtilisateur(
        prenom: UserManager.prenom,
        telephone: UserManager.telephone,
      );
      if (result != null) {
        UserManager.id = result['id'] ?? 1;
        HayaApiService.utilisateurId = UserManager.id;
        await UserManager.sauvegarder();
      }
    }
    final ok = await HayaApiService.creerDemande(
      telephone: _phoneCtrl.text,
      montant: _montant,
      objet: _objetCtrl.text.trim(),
      operateur: _op,
      reference: ref,
    );
    if (!ok) _demandeSauvegardee = false;
    return ok;
  }

  String _msg() {
    if (_ref.isEmpty) {
      _ref = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    final eur = TauxChangeService.fcfaVersEuros(_montant);
    final opNom = _op == 'tmoney' ? 'Tmoney' : 'Flooz';
    final montantFmt = _montant.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    final lien = 'https://haya.flexix.nl/pay/$_ref';
    return '💳 Demande de paiement — Haya\n\n'
        '👤 De : ${UserManager.nomComplet}\n'
        '💰 Montant : FCFA $montantFmt (~$eur EUR)\n'
        '📋 Objet : ${_objetCtrl.text}\n'
        '📱 Via : $opNom\n\n'
        '👇 Payez en 1 clic :\n$lien';
  }

  // ── Recevoir helpers ──
  String get _numRecevoir =>
      _opRecevoir == 'tmoney' ? NumerosManager.tmoney : NumerosManager.flooz;
  String get _nomOpRecevoir =>
      _opRecevoir == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Demander / Recevoir',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          if (_tab.index == 0)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DemandesScreen())),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          onTap: (_) => setState(() {}),
          indicatorColor: kOrange,
          indicatorWeight: 3,
          labelColor: kOrange,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Demander'),
            Tab(text: 'Recevoir'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildDemanderTab(),
          _buildRecevoirTab(),
        ],
      ),
    );
  }

  // ──────────────────────── ONGLET DEMANDER ────────────────────────
  Widget _buildDemanderTab() {
    final eur = _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';

    if (UserManager.nomComplet.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_outline, size: 56, color: kOrange),
            const SizedBox(height: 16),
            Text('Ton nom est requis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: kTextCtx(context))),
            const SizedBox(height: 10),
            Text('Ton nom apparaît sur les demandes de paiement. Ajoute-le avant de continuer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ParametresScreen()))
                    .then((_) => setState(() => _rafraichirOperateurs())),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Compléter mon profil',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.info_outline, color: kVert, size: 16),
          const SizedBox(width: 8),
          Text('Envoie une demande. Le destinataire paie via Haya !',
              style: TextStyle(fontSize: 13, color: kVert)),
        ]),
        const SizedBox(height: 20),
        Text('Montant (FCFA)',
            style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: kCardCtx(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('FCFA',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                        color: kSubtextCtx(context)))),
            Expanded(
              child: TextField(
                controller: _montantCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
                    color: kTextCtx(context)),
                decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                onChanged: (_) => setState(() { _ref = ''; _demandeSauvegardee = false; }),
              ),
            ),
          ]),
        ),
        if (_montant > 0 && NumerosManager.conversionEurOn)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              const Icon(Icons.euro, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('~$eur EUR',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        const SizedBox(height: 16),
        Text('Objet', style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: kCardCtx(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderCtx(context))),
          child: TextField(
            controller: _objetCtrl,
            style: TextStyle(fontSize: 15, color: kTextCtx(context)),
            decoration: const InputDecoration(
                hintText: 'Ex: Loyer, Remboursement...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            onChanged: (_) => setState(() { _ref = ''; _demandeSauvegardee = false; }),
          ),
        ),
        const SizedBox(height: 16),
        Text('Numéro de réception',
            style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
        const SizedBox(height: 8),
        if (NumerosManager.tmoney.isNotEmpty || NumerosManager.flooz.isNotEmpty) ...[
          Row(children: [
            if (NumerosManager.tmoney.isNotEmpty) ...[
              _ChipOp(label: 'Tmoney', numero: NumerosManager.tmoney, logo: 'M',
                  isSelected: _opSelectionne == 'tmoney', activeColor: kNuit,
                  onTap: () => setState(() {
                    _phoneCtrl.text = NumerosManager.tmoney;
                    _op = 'tmoney'; _opSelectionne = 'tmoney';
                  }), ctx: context),
              if (NumerosManager.flooz.isNotEmpty) const SizedBox(width: 8),
            ],
            if (NumerosManager.flooz.isNotEmpty)
              _ChipOp(label: 'Flooz', numero: NumerosManager.flooz, logo: 'F',
                  isSelected: _opSelectionne == 'flooz',
                  activeColor: const Color(0xFF854F0B),
                  onTap: () => setState(() {
                    _phoneCtrl.text = NumerosManager.flooz;
                    _op = 'flooz'; _opSelectionne = 'flooz';
                  }), ctx: context),
          ]),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOrange.withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.warning_amber_outlined, color: kOrange, size: 18),
                SizedBox(width: 8),
                Text('Aucun numéro enregistré',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: kOrange)),
              ]),
              const SizedBox(height: 6),
              const Text('Ajoutez vos numéros dans Paramètres.',
                  style: TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ParametresScreen()))
                    .then((_) => setState(() => _rafraichirOperateurs())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: kOrange, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Aller dans Paramètres',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            onPressed: _peut ? () async {
              if (_ref.isEmpty) {
                _ref = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
              }
              final ok = await _sauvegarderDemande(_ref);
              if (!ok) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Erreur de connexion. Réessaie.'),
                    backgroundColor: kRouge,
                    behavior: SnackBarBehavior.floating));
                return;
              }
              final lien = 'https://haya.flexix.nl/pay/$_ref?preview=1';
              launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication);
            } : null,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Voir et partager la demande',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent : kNuit,
                disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10 : Colors.grey.shade200,
                disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30 : Colors.grey,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? kOrange : Colors.white,
                side: Theme.of(context).brightness == Brightness.dark
                    ? const BorderSide(color: kOrange, width: 2) : BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _peut ? () async {
                final ok = await _sauvegarderDemande(_ref);
                if (!ok || !context.mounted) return;
                partagerWhatsApp(_msg());
              } : null,
              icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
              label: const Text('WhatsApp',
                  style: TextStyle(fontSize: 13, color: Color(0xFF25D366))),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF25D366)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _peut ? () async {
                final ok = await _sauvegarderDemande(_ref);
                if (!ok || !context.mounted) return;
                partagerSMS(_msg());
              } : null,
              icon: const Icon(Icons.sms_outlined, size: 16, color: kOrange),
              label: const Text('SMS',
                  style: TextStyle(fontSize: 13, color: kOrange)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kOrange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ──────────────────────── ONGLET RECEVOIR ────────────────────────
  Widget _buildRecevoirTab() {
    if (_opRecevoir.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.phone_android, size: 56, color: kOrange),
            const SizedBox(height: 16),
            Text('Aucun numéro enregistré',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: kTextCtx(context))),
            const SizedBox(height: 8),
            Text('Ajoute tes numéros Tmoney/Flooz dans Paramètres.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ParametresScreen()))
                  .then((_) => setState(() => _rafraichirOperateurs())),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Aller dans Paramètres',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        if (NumerosManager.tmoney.isNotEmpty && NumerosManager.flooz.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _TabOp(
                  label: 'Tmoney',
                  isActive: _opRecevoir == 'tmoney',
                  couleur: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF9B96E8) : const Color(0xFF3C3489),
                  onTap: () => setState(() => _opRecevoir = 'tmoney')),
              _TabOp(
                  label: 'Flooz',
                  isActive: _opRecevoir == 'flooz',
                  couleur: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFD4924A) : const Color(0xFF854F0B),
                  onTap: () => setState(() => _opRecevoir = 'flooz')),
            ]),
          ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: kCardCtx(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20, offset: const Offset(0, 4))
              ]),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: _opRecevoir == 'tmoney'
                      ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_nomOpRecevoir,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: _opRecevoir == 'tmoney'
                          ? const Color(0xFF3C3489) : const Color(0xFF854F0B))),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: 'haya://send?numero=$_numRecevoir&operateur=$_opRecevoir',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: _opRecevoir == 'tmoney'
                    ? const Color(0xFF3C3489) : const Color(0xFF854F0B),
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: _opRecevoir == 'tmoney'
                    ? const Color(0xFF3C3489) : const Color(0xFF854F0B),
              ),
            ),
            const SizedBox(height: 20),
            Text('+228 $_numRecevoir',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600,
                    letterSpacing: 1, color: kTextCtx(context))),
            const SizedBox(height: 4),
            Text(UserManager.nomComplet,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Scanner avec Haya pour payer',
                  style: TextStyle(fontSize: 11, color: kOrange,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '+228 $_numRecevoir'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Numéro copié !'),
                  backgroundColor: kVert,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copier le numéro',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(
                backgroundColor: kNuit,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _ChipOp extends StatelessWidget {
  final String label, numero, logo;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  final BuildContext ctx;
  const _ChipOp({
    required this.label, required this.numero, required this.logo,
    required this.isSelected, required this.activeColor,
    required this.onTap, required this.ctx,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: isSelected ? activeColor : kCardCtx(ctx),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? activeColor : kBorderCtx(ctx), width: 2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isSelected ? 0.25 : 0),
              borderRadius: BorderRadius.circular(5),
              border: isSelected ? null : Border.all(color: activeColor)),
          child: Center(
            child: Text(logo, style: TextStyle(
                color: isSelected ? Colors.white : activeColor,
                fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white70 : kSubtextCtx(ctx))),
          Text('+228 $numero', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : kTextCtx(ctx))),
        ]),
      ]),
    ),
  );
}

class _TabOp extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color couleur;
  final VoidCallback onTap;
  const _TabOp({required this.label, required this.isActive,
      required this.couleur, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: isActive ? kCardCtx(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: isActive ? couleur : Colors.grey)),
      ),
    ),
  );
}
