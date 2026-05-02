import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _sauvegarderDemande(String ref) async {
    try {
      await http.post(
        Uri.parse('${HayaApiService.baseUrl}/demandes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'expediteur_id': UserManager.id,
          'telephone_destinataire': _phoneCtrl.text,
          'montant': _montant,
          'objet': _objetCtrl.text.trim(),
          'operateur': _op,
          'reference': ref,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
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
    final nomEncode = Uri.encodeComponent(UserManager.nomComplet);
    final objetEncode = Uri.encodeComponent(_objetCtrl.text);
    final op = _op.isEmpty ? 'tmoney' : _op;
    final lienPaiement =
        'https://haya.flexix.nl/pay.html?n=${_phoneCtrl.text}&m=$_montant&nom=$nomEncode&obj=$objetEncode&op=$op&ref=$ref';
    final lignes = [
      '🟠 HAYA — Demande de paiement',
      '─────────────────────',
      '👤 De       : ${UserManager.nomComplet}',
      '💰 Montant : FCFA $montantFmt (~$eur EUR)',
      '📋 Objet   : ${_objetCtrl.text}',
      '📱 Via      : $opNom (+228 ${_phoneCtrl.text})',
      '─────────────────────',
      '👇 Payez en 1 clic :',
      lienPaiement,
      '─────────────────────',
      'Haya · Envoie. C est parti.',
    ];
    return lignes.join('\n');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFE7F6EF),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: kVert, size: 20),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Envoie une demande. Le destinataire paie via Haya !',
                      style: TextStyle(fontSize: 13, color: kVert))),
            ]),
          ),
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
                  onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          Text('Numero de reception',
              style:
                  TextStyle(fontSize: 13, color: kSubtextCtx(context))),
          const SizedBox(height: 8),
          if (NumerosManager.tmoney.isNotEmpty ||
              NumerosManager.flooz.isNotEmpty) ...[
            Row(children: [
              if (NumerosManager.tmoney.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _phoneCtrl.text = NumerosManager.tmoney;
                      _op = 'tmoney';
                      _opSelectionne = 'tmoney';
                    }),
                    child: Container(
                      margin: EdgeInsets.only(
                          right:
                              NumerosManager.flooz.isNotEmpty ? 8.0 : 0.0,
                          bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                          color: _opSelectionne == 'tmoney'
                              ? kNuit
                              : kCardCtx(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _opSelectionne == 'tmoney'
                                  ? kNuit
                                  : kBorderCtx(context),
                              width: 2)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.phone_android,
                                  size: 14,
                                  color: _opSelectionne == 'tmoney'
                                      ? Colors.white
                                      : kSubtextCtx(context)),
                              const SizedBox(width: 6),
                              Text('Tmoney',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _opSelectionne == 'tmoney'
                                          ? Colors.white70
                                          : kSubtextCtx(context))),
                            ]),
                            const SizedBox(height: 4),
                            Text('+228 ${NumerosManager.tmoney}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _opSelectionne == 'tmoney'
                                        ? Colors.white
                                        : kTextCtx(context))),
                          ]),
                    ),
                  ),
                ),
              if (NumerosManager.flooz.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _phoneCtrl.text = NumerosManager.flooz;
                      _op = 'flooz';
                      _opSelectionne = 'flooz';
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                          color: _opSelectionne == 'flooz'
                              ? const Color(0xFF854F0B)
                              : kCardCtx(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _opSelectionne == 'flooz'
                                  ? const Color(0xFF854F0B)
                                  : kBorderCtx(context),
                              width: 2)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.phone_android,
                                  size: 14,
                                  color: _opSelectionne == 'flooz'
                                      ? Colors.white
                                      : kSubtextCtx(context)),
                              const SizedBox(width: 6),
                              Text('Flooz',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _opSelectionne == 'flooz'
                                          ? Colors.white70
                                          : kSubtextCtx(context))),
                            ]),
                            const SizedBox(height: 4),
                            Text('+228 ${NumerosManager.flooz}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _opSelectionne == 'flooz'
                                        ? Colors.white
                                        : kTextCtx(context))),
                          ]),
                    ),
                  ),
                ),
            ]),
            if (_opSelectionne.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: kOrange),
                  const SizedBox(width: 6),
                  Text('Selectionnez votre numero de reception',
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
                      Text('Aucun numero enregistre',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kOrange)),
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                        'Ajoutez vos numeros Tmoney et/ou Flooz dans Parametres pour envoyer une demande.',
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
                        child: const Text('Aller dans Parametres',
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
                        await _sauvegarderDemande(_ref);
                      }
                      final nomEncode = Uri.encodeComponent(UserManager.nomComplet);
                      final objetEncode = Uri.encodeComponent(_objetCtrl.text);
                      final op = _op.isEmpty ? 'tmoney' : _op;
                      final lien =
                          'https://haya.flexix.nl/pay.html?n=${_phoneCtrl.text}&m=$_montant&nom=$nomEncode&obj=$objetEncode&op=$op&ref=$_ref&mode=preview';
                      launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication);
                    }
                  : null,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Voir et partager la demande',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNuit,
                  disabledBackgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _peut ? () async {
                  final msg = _msg();
                  await _sauvegarderDemande(_ref);
                  partagerWhatsApp(msg);
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
                  final msg = _msg();
                  await _sauvegarderDemande(_ref);
                  partagerSMS(msg);
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
