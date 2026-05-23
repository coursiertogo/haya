import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';
import '../services/taux_change_service.dart';
import '../feexpay_service.dart';
import 'pin_screen.dart';
import 'success_screen.dart';
import 'contacts_screen.dart';
import 'qr_scanner_screen.dart';
import 'parametres_screen.dart';

class SendScreen extends StatefulWidget {
  final String? numeroInitial;
  final int? montantInitial;
  final String? operateurInitial;
  final String? objetInitial;
  final String? refInitial;
  const SendScreen({
    super.key,
    this.numeroInitial,
    this.montantInitial,
    this.operateurInitial,
    this.objetInitial,
    this.refInitial,
  });
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _amountCtrl;
  String _op = '';
  bool _dejaPayee = false;
  String _compteSource = '';
  int _etape = 1;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.numeroInitial ?? '');
    _amountCtrl = TextEditingController(
        text: widget.montantInitial != null
            ? widget.montantInitial.toString()
            : '');
    if (widget.numeroInitial != null) {
      _op = detectOperateur(widget.numeroInitial!);
    }
    if (widget.operateurInitial != null) _op = widget.operateurInitial!;
    if (widget.refInitial != null) _verifierStatutDemande();
    _initCompteSource();
    // Si vient d'une demande OU si numéro+montant fournis → directement étape 3
    if (widget.refInitial != null ||
        (widget.numeroInitial != null && widget.montantInitial != null)) {
      _etape = 3;
    }
    // Sinon on commence à l'étape 1 (montant), le numéro sera pré-rempli à l'étape 2
  }

  void _initCompteSource() {
    if (NumerosManager.flooz.isNotEmpty) {
      _compteSource = 'flooz';
    } else {
      _compteSource = 'tmoney';
    }
  }

  Future<void> _verifierStatutDemande() async {
    HayaApiService.enregistrerPayeur(widget.refInitial!);
    final statut = await HayaApiService.getStatutDemande(widget.refInitial!);
    if (statut == 'paye' && mounted) {
      setState(() => _dejaPayee = true);
      final prefs = await SharedPreferences.getInstance();
      final liste = prefs.getStringList('pending_to_pay') ?? [];
      liste.remove(widget.refInitial);
      await prefs.setStringList('pending_to_pay', liste);
      await prefs.remove('pending_detail_${widget.refInitial}');
    }
  }

  int get _montant => int.tryParse(_amountCtrl.text) ?? 0;
  int get _frais => FeexPayService.calculerFrais(_montant);
  int get _total => _montant + _frais;
  String get _eur =>
      _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';
  String get _eurTotal =>
      _total > 0 ? TauxChangeService.fcfaVersEuros(_total) : '0.00';
  bool get _peut =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
      (_op == 'tmoney' || _op == 'flooz') &&
      _montant > 0 &&
      !_dejaPayee &&
      _compteSourceValide;

  bool get _compteSourceValide {
    if (_compteSource == 'tmoney') return NumerosManager.tmoney.isNotEmpty;
    if (_compteSource == 'flooz') return NumerosManager.flooz.isNotEmpty;
    return false;
  }

  String get _messageCompteManquant {
    final op = _compteSource == 'tmoney' ? 'Tmoney' : 'Flooz';
    return 'Ajoute ton numéro $op dans Paramètres pour payer.';
  }


  void _confirmerPin() {
    if (!PinManager.pinDefini) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PinScreen(
                    titre: 'Sécurisez vos transferts',
                    sousTitre:
                        'Créez un code PIN à 6 chiffres.\nCe PIN vous sera demandé à chaque transfert.\nIl est différent de votre mot de passe.',
                    modeDefinition: true,
                    onSuccess: (_) async {
                      Navigator.pop(context);
                      await _executer();
                    },
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PinScreen(
                    titre: 'Confirmer le transfert',
                    sousTitre:
                        'PIN pour valider\nFCFA $_montant vers +228 ${_phoneCtrl.text}',
                    onSuccess: (_) async {
                      Navigator.pop(context);
                      await _executer();
                    },
                  )));
    }
  }

  Future<void> _executer() async {
    bool annule = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmationCountdownDialog(
        montant: _montant,
        numero: _phoneCtrl.text,
        operateur: _op == 'tmoney' ? 'Tmoney' : 'Flooz',
        onAnnuler: () {
          annule = true;
          Navigator.pop(ctx);
        },
        onConfirmer: () => Navigator.pop(ctx),
      ),
    );
    if (annule) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TransfertProgressDialog(
            numero: _phoneCtrl.text,
            operateur: _op == 'tmoney' ? 'Tmoney' : 'Flooz',
            montant: _montant));
    await Future.delayed(const Duration(seconds: 1));
    final ref = FeexPayService.genererReference();

    // requesttopay = débiter le compte choisi par l'expéditeur
    final senderTel = _compteSource == 'tmoney'
        ? NumerosManager.tmoney
        : NumerosManager.flooz;
    // Collection = montantTotal (montant + 3% frais Haya)
    // Payout = _montant (montant exact de la demande)
    final result = await FeexPayService.initierPaiement(
      telephone: senderTel,
      montant: FeexPayService.montantTotal(_montant),
      reseau: _compteSource,
      reference: ref,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (result['success']) {
      if (!mounted) return;
      HayaApiService.enregistrerTransaction(
        telephone: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
        montant: _montant,
        operateur: _op == 'tmoney' ? 'Tmoney' : 'Flooz',
        reference: ref,
      );
      // marquerDemandePaye est fait dans SuccessScreen après confirmation USSD
      if (!mounted) return;
      final route = MaterialPageRoute(
          builder: (_) => SuccessScreen(
                montant: _montant,
                numero: _phoneCtrl.text,
                operateur: _op == 'tmoney'
                    ? 'Mixx by Yas (Tmoney)'
                    : 'Flooz (Moov Africa)',
                frais: _frais,
                transactionId: result['transactionId'] ?? '',
                numeroDestinataire: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
                operateurDestinataire: _op,
                referenceHaya: ref,
                demandeRef: widget.refInitial,
              ));
      if (widget.refInitial != null) {
        Navigator.pushReplacement(context, route);
      } else {
        Navigator.push(context, route);
      }
    } else {
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: kCardCtx(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFEF0F0), shape: BoxShape.circle),
                      child: const Icon(Icons.error_outline,
                          color: kRouge, size: 36)),
                  const SizedBox(height: 16),
                  Text('Transfert échoué',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kTextCtx(context))),
                  const SizedBox(height: 8),
                  Text(
                      result['message'] ??
                          'Une erreur est survenue. Verifie ta connexion et reessaie.',
                      style: TextStyle(
                          fontSize: 13, color: kSubtextCtx(context)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kBorderCtx(context)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text('Fermer',
                            style:
                                TextStyle(color: kSubtextCtx(context))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmerPin();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kNuit,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Réessayer',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ]),
                ]),
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nombre total d'étapes (si demande pré-remplie → 1 étape résumé seulement)
    final totalEtapes = widget.refInitial != null ? 1 : 3;
    final etapeAffichee = widget.refInitial != null ? 1 : _etape;

    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_etape > 1 && widget.refInitial == null) {
              setState(() => _etape--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.objetInitial != null
              ? 'Payer · ${widget.objetInitial}'
              : 'Envoyer · $etapeAffichee/$totalEtapes',
          style: const TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: etapeAffichee / totalEtapes,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
          ),
        ),
      ),
      body: widget.refInitial != null
          ? _buildEtape3(context)
          : _etape == 1
              ? _buildEtape1(context)
              : _etape == 2
                  ? _buildEtape2(context)
                  : _buildEtape3(context),
    );
  }

  // ─── ÉTAPE 1 : MONTANT ───────────────────────────────────
  Widget _buildEtape1(BuildContext context) {
    const suggestions = [1000, 2000, 5000, 10000, 25000];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Text('Quel montant ?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextCtx(context))),
        const SizedBox(height: 6),
        Text('Frais Haya : 3% · ~$_eur EUR',
            style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: kInputCtx(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderCtx(context)),
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text('FCFA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kSubtextCtx(context))),
            ),
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                enabled: widget.montantInitial == null,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kTextCtx(context)),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(fontSize: 24, color: kSubtextCtx(context)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            final sel = _montant == s;
            return GestureDetector(
              onTap: widget.montantInitial == null
                  ? () { _amountCtrl.text = s.toString(); setState(() {}); }
                  : null,
              child: Chip(
                label: Text('$s'),
                backgroundColor: sel ? kOrange : kCardCtx(context),
                labelStyle: TextStyle(
                  color: sel ? Colors.white : kTextCtx(context),
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(color: sel ? kOrange : kBorderCtx(context)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _montant > 0 ? () => setState(() => _etape = 2) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kNuit,
              disabledBackgroundColor: kBorderCtx(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Suivant',
                  style: TextStyle(
                    color: _montant > 0 ? Colors.white : kSubtextCtx(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18,
                  color: _montant > 0 ? Colors.white : kSubtextCtx(context)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── ÉTAPE 2 : NUMÉRO BÉNÉFICIAIRE ──────────────────────
  Widget _buildEtape2(BuildContext context) {
    Color opColor = Colors.grey;
    String opLabel = 'Opérateur non reconnu';
    if (_op == 'tmoney') { opColor = const Color(0xFF007AFF); opLabel = 'Mixx by Yas (Tmoney)'; }
    if (_op == 'flooz')  { opColor = const Color(0xFFFF6600); opLabel = 'Flooz (Moov Africa)'; }
    final valide = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
        (_op == 'tmoney' || _op == 'flooz');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Text('Numéro bénéficiaire',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextCtx(context))),
        const SizedBox(height: 6),
        Text('Numéro Togo (+228)',
            style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: kInputCtx(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderCtx(context)),
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Text('+228',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kSubtextCtx(context))),
            ),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                enabled: widget.numeroInitial == null,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 18, color: kTextCtx(context)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '00 00 00 00',
                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                ),
                onChanged: (v) => setState(() => _op = detectOperateur(v)),
              ),
            ),
            if (widget.numeroInitial == null) ...[
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: kOrange),
                onPressed: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                  if (result != null && mounted) {
                    final digits = result.replaceAll(RegExp(r'\D'), '');
                    final tel = digits.length > 8 ? digits.substring(digits.length - 8) : digits;
                    _phoneCtrl.text = tel;
                    setState(() => _op = detectOperateur(tel));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.contacts_outlined, color: kOrange),
                onPressed: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  );
                  if (result != null && mounted) {
                    final digits = result.replaceAll(RegExp(r'\D'), '');
                    final tel = digits.length > 8 ? digits.substring(digits.length - 8) : digits;
                    _phoneCtrl.text = tel;
                    setState(() => _op = detectOperateur(tel));
                  }
                },
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        if (_phoneCtrl.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: opColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: opColor.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 8, color: opColor),
              const SizedBox(width: 6),
              Text(opLabel,
                  style: TextStyle(fontSize: 13, color: opColor, fontWeight: FontWeight.w500)),
            ]),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: valide ? () => setState(() => _etape = 3) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kNuit,
              disabledBackgroundColor: kBorderCtx(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Suivant',
                  style: TextStyle(
                    color: valide ? Colors.white : kSubtextCtx(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18,
                  color: valide ? Colors.white : kSubtextCtx(context)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── ÉTAPE 3 : COMPTE SOURCE + CONFIRMATION ──────────────
  Widget _buildEtape3(BuildContext context) {
    final hasTmoney = NumerosManager.tmoney.isNotEmpty;
    final hasFlooz  = NumerosManager.flooz.isNotEmpty;
    final hasBoth   = hasTmoney && hasFlooz;
    final opLabel   = _op == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';
    final srcLabel  = _compteSource == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';

    String fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Text('Payer depuis',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextCtx(context))),
        const SizedBox(height: 6),
        Text('Choisir le compte source',
            style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
        const SizedBox(height: 20),

        if (hasBoth) ...[
          Row(children: [
            Expanded(child: _CompteBtn(
              label: 'Tmoney', numero: NumerosManager.tmoney,
              selected: _compteSource == 'tmoney',
              onTap: () => setState(() => _compteSource = 'tmoney'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _CompteBtn(
              label: 'Flooz', numero: NumerosManager.flooz,
              selected: _compteSource == 'flooz',
              onTap: () => setState(() => _compteSource = 'flooz'),
            )),
          ]),
          const SizedBox(height: 20),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardCtx(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderCtx(context)),
          ),
          child: Column(children: [
            _FeeRow(label: 'Vers', valeur: '+228 ${_phoneCtrl.text}', context: context),
            Divider(height: 16, color: kBorderCtx(context)),
            _FeeRow(label: 'Réseau destinataire', valeur: opLabel, context: context),
            Divider(height: 16, color: kBorderCtx(context)),
            _FeeRow(label: 'Montant', valeur: 'FCFA ${fmt(_montant)}', context: context),
            _FeeRow(label: 'Frais (3%)', valeur: 'FCFA ${fmt(_frais)}', context: context),
            Divider(height: 16, color: kBorderCtx(context)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total débité',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextCtx(context))),
              Text('FCFA ${fmt(_total)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kOrange)),
            ]),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('~$_eurTotal EUR',
                  style: TextStyle(fontSize: 11, color: kSubtextCtx(context))),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        if (_dejaPayee)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kVert.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kVert.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: kVert, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Cette demande a déjà été payée.',
                    style: TextStyle(fontSize: 13, color: kVert, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),

        if (!_compteSourceValide) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kRouge.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kRouge.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: kRouge, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_messageCompteManquant,
                    style: const TextStyle(fontSize: 12, color: kRouge)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ParametresScreen())),
                  child: const Text('Ajouter dans Paramètres →',
                      style: TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.w600)),
                ),
              ])),
            ]),
          ),
        ],

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _peut ? _confirmerPin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              disabledBackgroundColor: kBorderCtx(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _dejaPayee
                  ? 'Demande déjà payée'
                  : _peut
                      ? 'Envoyer via $srcLabel'
                      : 'Envoyer',
              style: TextStyle(
                color: _peut ? Colors.white : kSubtextCtx(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── DIALOG COMPTE À REBOURS ─────────────────────────────
class _ConfirmationCountdownDialog extends StatefulWidget {
  final int montant;
  final String numero, operateur;
  final VoidCallback onAnnuler, onConfirmer;
  const _ConfirmationCountdownDialog({
    required this.montant,
    required this.numero,
    required this.operateur,
    required this.onAnnuler,
    required this.onConfirmer,
  });
  @override
  State<_ConfirmationCountdownDialog> createState() =>
      _ConfirmationCountdownDialogState();
}

class _ConfirmationCountdownDialogState
    extends State<_ConfirmationCountdownDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _secondes = 5;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..forward();
    _demarrerCompte();
  }

  void _demarrerCompte() async {
    for (int i = 5; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _secondes = i);
      if (i == 0) widget.onConfirmer();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eur = TauxChangeService.fcfaVersEuros(widget.montant);
    final montantFmt = widget.montant
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kCardCtx(context),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 80,
              height: 80,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CircularProgressIndicator(
                    value: 1 - _ctrl.value,
                    color: kOrange,
                    backgroundColor: kBorderCtx(context),
                    strokeWidth: 5),
              ),
            ),
            Text('$_secondes',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: kTextCtx(context))),
          ]),
          const SizedBox(height: 20),
          Text("Confirmer l'envoi ?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextCtx(context))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Montant',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context))),
                Text('FCFA $montantFmt',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextCtx(context))),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Equivalent',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context))),
                Text('~$eur EUR',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Vers',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context))),
                Text('+228 ${widget.numero}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kTextCtx(context))),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Via',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context))),
                Text(widget.operateur,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kTextCtx(context))),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Envoi automatique dans $_secondes sec...',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAnnuler,
              icon: const Icon(Icons.close, size: 18, color: kRouge),
              label: const Text('Annuler',
                  style: TextStyle(
                      color: kRouge,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kRouge),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── DIALOG STATUT TRANSFERT ─────────────────────────────
class _TransfertProgressDialog extends StatefulWidget {
  final String numero, operateur;
  final int montant;
  const _TransfertProgressDialog(
      {required this.numero,
      required this.operateur,
      required this.montant});
  @override
  State<_TransfertProgressDialog> createState() =>
      _TransfertProgressDialogState();
}

class _TransfertProgressDialogState
    extends State<_TransfertProgressDialog> {
  int _etape = 0;
  final _etapes = [
    'Connexion sécurisée...',
    'Vérification du numéro...',
    'Traitement du paiement...',
    'Confirmation en cours...'
  ];

  @override
  void initState() {
    super.initState();
    _progresser();
  }

  void _progresser() async {
    for (int i = 0; i < _etapes.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _etape = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: Color(0xFFE7F0FF), shape: BoxShape.circle),
              child: const CircularProgressIndicator(
                  color: kNuit, strokeWidth: 3)),
          const SizedBox(height: 20),
          Text('FCFA ${widget.montant}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: kNuit)),
          const SizedBox(height: 4),
          Text('vers +228 ${widget.numero}',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          ..._etapes.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.key < _etape
                            ? kVert
                            : e.key == _etape
                                ? kOrange
                                : Colors.grey.shade200),
                    child: Icon(
                        e.key < _etape ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value,
                      style: TextStyle(
                          fontSize: 13,
                          color: e.key < _etape
                              ? kVert
                              : e.key == _etape
                                  ? kNuit
                                  : Colors.grey,
                          fontWeight: e.key == _etape
                              ? FontWeight.w500
                              : FontWeight.normal)),
                ]),
              )),
        ]),
      ),
    );
  }
}

// ─── WIDGETS INTERNES ────────────────────────────────────

class _FeeRow extends StatelessWidget {
  final String label, valeur;
  final BuildContext context;
  const _FeeRow(
      {required this.label, required this.valeur, required this.context});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
          Text(valeur,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextCtx(context))),
        ]),
      );
}

class _CompteBtn extends StatelessWidget {
  final String label, numero;
  final bool selected;
  final VoidCallback onTap;
  const _CompteBtn(
      {required this.label,
      required this.numero,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kNuit : kCardCtx(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? kNuit : kBorderCtx(context),
              width: selected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : kTextCtx(context))),
          const SizedBox(height: 4),
          Text('+228 $numero',
              style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white70 : kSubtextCtx(context))),
        ]),
      ),
    );
  }
}

