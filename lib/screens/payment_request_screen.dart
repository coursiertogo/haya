import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';
import '../services/taux_change_service.dart';
import 'parametres_screen.dart';
import 'demandes_screen.dart';

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
  String _opSelectionne = '';
  String _ref = '';
  bool _demandeSauvegardee = false;

  @override
  void initState() {
    super.initState();
    if (NumerosManager.tmoney.isNotEmpty) {
      _phoneCtrl.text = NumerosManager.tmoney;
      _op = 'tmoney';
      _opSelectionne = 'tmoney';
    } else if (NumerosManager.flooz.isNotEmpty) {
      _phoneCtrl.text = NumerosManager.flooz;
      _op = 'flooz';
      _opSelectionne = 'flooz';
    }
  }

  int get _montant => int.tryParse(_montantCtrl.text) ?? 0;

  Future<bool> _sauvegarderDemande(String ref) async {
    if (_demandeSauvegardee) return true;
    _demandeSauvegardee = true;
    // S'assurer que l'utilisateur existe en backend
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
  bool get _peut =>
      _montant > 0 &&
      _objetCtrl.text.isNotEmpty &&
      _phoneCtrl.text.length == 8 &&
      (_opSelectionne == 'tmoney' || _opSelectionne == 'flooz') &&
      (NumerosManager.tmoney.isNotEmpty || NumerosManager.flooz.isNotEmpty);

  String _msg() {
    if (_ref.isEmpty) {
      _ref = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    final ref = _ref;
    final eur = TauxChangeService.fcfaVersEuros(_montant);
    final opNom = _op == 'tmoney'
        ? 'Tmoney'
        : _op == 'flooz'
            ? 'Flooz'
            : 'Mobile Money';
    final montantFmt = _montant.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => (m[1] ?? '') + ' ');
    final lienPaiement = 'https://haya.flexix.nl/pay/$ref';
    return '💳 Demande de paiement — Haya\n\n'
        '👤 De : ${UserManager.nomComplet}\n'
        '💰 Montant : FCFA $montantFmt (~$eur EUR)\n'
        '📋 Objet : ${_objetCtrl.text}\n'
        '📱 Via : $opNom\n\n'
        '👇 Payez en 1 clic :\n'
        '$lienPaiement';
  }

  @override
  Widget build(BuildContext context) {
    final eur =
        _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
          backgroundColor: kNuit,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: const Text('Demande de paiement',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DemandesScreen())),
            )
          ]),
      body: UserManager.nomComplet.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_outline, size: 56, color: kOrange),
                  const SizedBox(height: 16),
                  Text('Ton nom est requis',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kTextCtx(context))),
                  const SizedBox(height: 10),
                  Text(
                      'Ton nom apparaît sur les demandes de paiement. Ajoute-le avant de continuer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ParametresScreen()),
                      ).then((_) => setState(() {})),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Compléter mon profil',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            )
          : SingleChildScrollView(
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
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kSubtextCtx(context)))),
              Expanded(
                child: TextField(
                  controller: _montantCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: kTextCtx(context)),
                  decoration: const InputDecoration(
                      hintText: '0', border: InputBorder.none),
                  onChanged: (_) => setState(() {
                    _ref = '';
                    _demandeSauvegardee = false;
                  }),
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
          Text('Objet',
              style:
                  TextStyle(fontSize: 13, color: kSubtextCtx(context))),
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              onChanged: (_) => setState(() {
                _ref = '';
                _demandeSauvegardee = false;
              }),
            ),
          ),
          const SizedBox(height: 16),
          Text('Numéro de réception',
              style:
                  TextStyle(fontSize: 13, color: kSubtextCtx(context))),
          const SizedBox(height: 8),
          if (NumerosManager.tmoney.isNotEmpty ||
              NumerosManager.flooz.isNotEmpty) ...[
            Row(children: [
              if (NumerosManager.tmoney.isNotEmpty) ...[
                _ChipOperateur(
                  label: 'Tmoney',
                  numero: NumerosManager.tmoney,
                  logo: 'M',
                  isSelected: _opSelectionne == 'tmoney',
                  activeColor: kNuit,
                  onTap: () => setState(() {
                    _phoneCtrl.text = NumerosManager.tmoney;
                    _op = 'tmoney';
                    _opSelectionne = 'tmoney';
                  }),
                  context: context,
                ),
                if (NumerosManager.flooz.isNotEmpty) const SizedBox(width: 8),
              ],
              if (NumerosManager.flooz.isNotEmpty)
                _ChipOperateur(
                  label: 'Flooz',
                  numero: NumerosManager.flooz,
                  logo: 'F',
                  isSelected: _opSelectionne == 'flooz',
                  activeColor: const Color(0xFF854F0B),
                  onTap: () => setState(() {
                    _phoneCtrl.text = NumerosManager.flooz;
                    _op = 'flooz';
                    _opSelectionne = 'flooz';
                  }),
                  context: context,
                ),
            ]),
            if (_opSelectionne.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 14, color: kOrange),
                  const SizedBox(width: 6),
                  Text('Sélectionnez votre numéro de réception',
                      style: TextStyle(fontSize: 12, color: kOrange)),
                ]),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: kOrange.withValues(alpha: 0.3))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.warning_amber_outlined,
                          color: kOrange, size: 18),
                      SizedBox(width: 8),
                      Text('Aucun numéro enregistré',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kOrange)),
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                        'Ajoutez vos numéros Tmoney et/ou Flooz dans Paramètres pour envoyer une demande.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ParametresScreen())).then((_) {
                        setState(() {
                          if (NumerosManager.tmoney.isNotEmpty) {
                            _phoneCtrl.text = NumerosManager.tmoney;
                            _op = 'tmoney';
                            _opSelectionne = 'tmoney';
                          } else if (NumerosManager.flooz.isNotEmpty) {
                            _phoneCtrl.text = NumerosManager.flooz;
                            _op = 'flooz';
                            _opSelectionne = 'flooz';
                          }
                        });
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: kOrange,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Aller dans Paramètres',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
            ),
          ],
          if (_peut) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: kInputCtx(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderCtx(context))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apercu',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextCtx(context))),
                    const SizedBox(height: 8),
                    Text(
                        NumerosManager.conversionEurOn
                            ? 'FCFA ${_montantCtrl.text} (~$eur EUR)'
                            : 'FCFA ${_montantCtrl.text}',
                        style: TextStyle(
                            fontSize: 12, color: kTextCtx(context))),
                    Text('Objet : ${_objetCtrl.text}',
                        style: TextStyle(
                            fontSize: 12, color: kTextCtx(context))),
                  ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _peut
                  ? () async {
                      if (_ref.isEmpty) {
                        _ref = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      }
                      final ok = await _sauvegarderDemande(_ref);
                      if (!ok) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Erreur de connexion. Réessaie.'),
                            backgroundColor: kRouge,
                            behavior: SnackBarBehavior.floating));
                        return;
                      }
                      final lien = 'https://haya.flexix.nl/pay/$_ref?preview=1';
                      launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication);
                    }
                  : null,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Voir et partager la demande',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.transparent
                      : kNuit,
                  disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Colors.grey.shade200,
                  disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white30
                      : Colors.grey,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                      ? kOrange
                      : Colors.white,
                  side: Theme.of(context).brightness == Brightness.dark
                      ? const BorderSide(color: kOrange, width: 2)
                      : BorderSide.none,
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
                icon: const Icon(Icons.chat,
                    size: 16, color: Color(0xFF25D366)),
                label: const Text('WhatsApp',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF25D366))),
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
                icon: const Icon(Icons.sms_outlined,
                    size: 16, color: kOrange),
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
          const SizedBox(height: 10),
          Center(
              child: Text('Le destinataire paie via Haya',
                  style: TextStyle(
                      fontSize: 11, color: kSubtextCtx(context)))),
        ]),
      ),
    );
  }
}

class _ChipOperateur extends StatelessWidget {
  final String label, numero, logo;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  final BuildContext context;
  const _ChipOperateur({
    required this.label, required this.numero, required this.logo,
    required this.isSelected, required this.activeColor,
    required this.onTap, required this.context,
  });
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: isSelected ? activeColor : kCardCtx(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? activeColor : kBorderCtx(context),
              width: 2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.25) : activeColor,
              borderRadius: BorderRadius.circular(5)),
          child: Center(
            child: Text(logo, style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white70 : kSubtextCtx(context))),
          Text('+228 $numero', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : kTextCtx(context))),
        ]),
      ]),
    ),
  );
}
