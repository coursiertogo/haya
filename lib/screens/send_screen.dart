import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';
import '../services/taux_change_service.dart';
import '../feexpay_service.dart';
import 'pin_screen.dart';
import 'success_screen.dart';
import 'contacts_screen.dart';

class SendScreen extends StatefulWidget {
  final String? numeroInitial;
  final int? montantInitial;
  final String? operateurInitial;
  final String? objetInitial;
  const SendScreen({
    super.key,
    this.numeroInitial,
    this.montantInitial,
    this.operateurInitial,
    this.objetInitial,
  });
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _amountCtrl;
  String _op = '';

  @override
  void initState() {
    super.initState();
    _phoneCtrl =
        TextEditingController(text: widget.numeroInitial ?? '');
    _amountCtrl = TextEditingController(
        text: widget.montantInitial != null
            ? widget.montantInitial.toString()
            : '');
    if (widget.numeroInitial != null) {
      _op = detectOperateur(widget.numeroInitial!);
    }
    if (widget.operateurInitial != null) _op = widget.operateurInitial!;
  }

  int get _montant => int.tryParse(_amountCtrl.text) ?? 0;
  int get _frais =>
      _montant > 0 ? (_montant * 0.01).round().clamp(10, 999999) : 0;
  int get _total => _montant + _frais;
  String get _eur =>
      _montant > 0 ? TauxChangeService.fcfaVersEuros(_montant) : '0.00';
  String get _eurTotal =>
      _total > 0 ? TauxChangeService.fcfaVersEuros(_total) : '0.00';
  bool get _peut =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
      (_op == 'tmoney' || _op == 'flooz') &&
      _montant > 0;

  void _confirmerPin() {
    if (!PinManager.pinDefini) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PinScreen(
                    titre: 'Securisez vos transferts',
                    sousTitre:
                        'Creez un code PIN a 4 chiffres.\nCe PIN vous sera demande a chaque transfert.\nIl est different de votre mot de passe.',
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
    final result = await FeexPayService.initierPaiement(
      telephone: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      montant: _montant,
      reseau: FeexPayService.convertirOperateur(_op),
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
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SuccessScreen(
                    montant: _montant,
                    numero: _phoneCtrl.text,
                    operateur: _op == 'tmoney'
                        ? 'Mixx by Yas (Tmoney)'
                        : 'Flooz (Moov Africa)',
                    frais: _frais,
                  )));
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
                  Text('Transfert echoue',
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
                        child: const Text('Reessayer',
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
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
          backgroundColor: kNuit,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Envoyer',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          if (widget.objetInitial != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kOrange.withOpacity(0.25))),
              child: Row(children: [
                const Icon(Icons.receipt_outlined, color: kOrange, size: 18),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Demande de paiement',
                      style: TextStyle(
                          fontSize: 11,
                          color: kOrange.withOpacity(0.8))),
                  Text(widget.objetInitial!,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kOrange)),
                ]),
              ]),
            ),
          ],
          Text('Montant (FCFA)',
              style:
                  TextStyle(fontSize: 13, color: kSubtextCtx(context))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: widget.montantInitial != null
                    ? kInputCtx(context)
                    : kCardCtx(context),
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
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  readOnly: widget.montantInitial != null,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: kTextCtx(context)),
                  decoration: const InputDecoration(
                      hintText: '0', border: InputBorder.none),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (widget.montantInitial != null)
                const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.lock_outline,
                        size: 16, color: Colors.grey)),
            ]),
          ),
          if (_montant > 0 && NumerosManager.conversionEurOn)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                const Icon(Icons.euro, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('~$_eur EUR',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          if (widget.montantInitial == null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [1000, 2000, 5000, 10000, 25000]
                  .map((v) => GestureDetector(
                        onTap: () =>
                            setState(() => _amountCtrl.text = v.toString()),
                        child: Chip(
                          label: Text(v
                              .toString()
                              .replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]} '),
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: kCardCtx(context),
                          side: BorderSide(color: kBorderCtx(context)),
                          padding: EdgeInsets.zero,
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text('Numero du beneficiaire',
              style:
                  TextStyle(fontSize: 13, color: kSubtextCtx(context))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: widget.numeroInitial != null
                    ? kInputCtx(context)
                    : kCardCtx(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderCtx(context))),
            child: Row(children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('+228',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kSubtextCtx(context)))),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  readOnly: widget.numeroInitial != null,
                  style:
                      TextStyle(fontSize: 16, color: kTextCtx(context)),
                  decoration: const InputDecoration(
                      hintText: 'XX XX XX XX',
                      border: InputBorder.none,
                      counterText: ''),
                  onChanged: (v) =>
                      setState(() => _op = detectOperateur(v)),
                ),
              ),
              if (widget.numeroInitial != null)
                const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.lock_outline,
                        size: 16, color: Colors.grey))
              else
                IconButton(
                  icon: Icon(Icons.contacts_outlined,
                      color: kSubtextCtx(context), size: 22),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContactsScreen())),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          if (_op == 'tmoney')
            _OperateurBox(
                nom: 'Mixx by Yas (Tmoney)',
                sub: 'Yas Togo',
                couleur: const Color(0xFFEEEDFE),
                bordure: const Color(0xFFAFA9EC),
                textColor: kNuit,
                logo: 'M'),
          if (_op == 'flooz')
            _OperateurBox(
                nom: 'Flooz (Moov Africa)',
                sub: 'Moov Africa Togo',
                couleur: const Color(0xFFFFF5EA),
                bordure: const Color(0xFFFAC775),
                textColor: const Color(0xFF854F0B),
                logo: 'F'),
          if (_op == 'inconnu')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF0F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF7C1C1))),
              child: const Row(children: [
                Icon(Icons.error_outline, color: kRouge, size: 20),
                SizedBox(width: 8),
                Text('Numero non reconnu',
                    style: TextStyle(color: kRouge, fontSize: 13)),
              ]),
            ),
          const SizedBox(height: 16),
          _FeeRow(
            label: 'Frais Haya (1%)',
            valeur:
                'FCFA ${_frais.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
            context: context,
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: TextStyle(
                          fontSize: 12, color: kSubtextCtx(context))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                        'FCFA ${_total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTextCtx(context))),
                    if (_total > 0 && NumerosManager.conversionEurOn)
                      Text('~$_eurTotal EUR',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                  ]),
                ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _peut ? _confirmerPin : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNuit,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text(
                _peut
                    ? 'Envoyer via ${_op == "tmoney" ? "Tmoney" : "Flooz"}'
                    : 'Confirmer le transfert',
                style: TextStyle(
                    color: _peut ? Colors.white : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
              child: Text('Securise par Haya · Togo',
                  style: TextStyle(fontSize: 11, color: Colors.grey))),
        ]),
      ),
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
    'Connexion securisee...',
    'Verification du numero...',
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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bordure)),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: textColor, borderRadius: BorderRadius.circular(9)),
              child: Center(
                  child: Text(logo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
      );
}

class _FeeRow extends StatelessWidget {
  final String label, valeur;
  final BuildContext context;
  const _FeeRow(
      {required this.label, required this.valeur, required this.context});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: kInputCtx(context),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: kSubtextCtx(context))),
          Text(valeur,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextCtx(context))),
        ]),
      );
}
