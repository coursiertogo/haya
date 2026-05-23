import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/taux_change_service.dart';
import '../services/managers.dart';
import '../feexpay_service.dart';
import '../services/haya_api_service.dart';

class SuccessScreen extends StatefulWidget {
  final int montant, frais;
  final String numero, operateur;
  final String transactionId;
  final String numeroDestinataire;
  final String operateurDestinataire;
  final String referenceHaya;
  final String? demandeRef;
  const SuccessScreen({
    super.key,
    required this.montant,
    required this.numero,
    required this.operateur,
    required this.frais,
    this.transactionId = '',
    this.numeroDestinataire = '',
    this.operateurDestinataire = '',
    this.referenceHaya = '',
    this.demandeRef,
  });
  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  late String _ref;
  String _statut = 'pending';
  String _erreurPayout = '';

  @override
  void initState() {
    super.initState();
    _ref = 'TG-${(10000 + DateTime.now().millisecond * 9)}';
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _notif();
    });
    if (FeexPayService.modeSandbox) {
      setState(() => _statut = 'success');
    } else {
      _pollStatut();
    }
  }

  Future<void> _pollStatut() async {
    const maxTentatives = 12;
    for (int i = 0; i < maxTentatives; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      final statut = await FeexPayService.verifierStatut(widget.transactionId);
      if (statut == 'SUCCESSFUL') {
        if (widget.numeroDestinataire.isNotEmpty) {
          final payout = await FeexPayService.payerDestinataire(
            telephone: widget.numeroDestinataire,
            montant: widget.montant,
            reseau: widget.operateurDestinataire,
            reference: widget.referenceHaya,
          );
          if (!payout['success']) {
            if (mounted) {
              setState(() {
                _statut = 'failed';
                _erreurPayout = payout['message'] ?? '';
              });
              HapticFeedback.vibrate();
            }
            return;
          }
        }
        if (mounted) {
          setState(() => _statut = 'success');
          HapticFeedback.heavyImpact();
          if (widget.demandeRef != null) {
            await HayaApiService.marquerDemandePaye(widget.demandeRef!);
          }
        }
        return;
      }
      if (statut == 'FAILED') {
        if (mounted) setState(() => _statut = 'failed');
        HapticFeedback.vibrate();
        return;
      }
    }
    if (widget.numeroDestinataire.isNotEmpty) {
      final payout = await FeexPayService.payerDestinataire(
        telephone: widget.numeroDestinataire,
        montant: widget.montant,
        reseau: widget.operateurDestinataire,
        reference: widget.referenceHaya,
      );
      if (mounted && _statut == 'pending') {
        if (payout['success']) {
          setState(() => _statut = 'success');
          if (widget.demandeRef != null) {
            await HayaApiService.marquerDemandePaye(widget.demandeRef!);
          }
        } else {
          setState(() {
            _statut = 'failed';
            _erreurPayout = payout['message'] ?? '';
          });
        }
      }
    } else if (mounted && _statut == 'pending') {
      setState(() {
        _statut = 'failed';
        _erreurPayout = 'Impossible de confirmer le paiement. Vérifiez votre compte mobile money.';
      });
      HapticFeedback.vibrate();
    }
  }

  void _notif() {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: _NotificationBanner(
          montant: widget.montant,
          numero: widget.numero,
          operateur: widget.operateur,
          onDismiss: () => e.remove(),
        ),
      ),
    );
    overlay.insert(e);
    Future.delayed(const Duration(seconds: 4), () {
      if (e.mounted) e.remove();
    });
  }

  void _partagerTexte() {
    final eur = TauxChangeService.fcfaVersEuros(widget.montant);
    final recu = '''
🧾 REÇU HAYA
─────────────────────
📤 Transfert envoyé
─────────────────────
Montant    : FCFA ${widget.montant}${NumerosManager.conversionEurOn ? ' (~$eur EUR)' : ''}
Frais      : FCFA ${widget.frais}
Opérateur  : ${widget.operateur}
Destinataire : +228 ${widget.numero}
Date       : ${_fmtDate(DateTime.now())}
Référence  : #$_ref
─────────────────────
✅ Transaction confirmée
Envoyé via Haya
"Envoie. C'est parti."
''';

    showModalBottomSheet(
      context: context,
      backgroundColor: kCardCtx(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Partager le reçu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: kTextCtx(context))),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(12)),
            child: Text(recu,
                style: TextStyle(fontSize: 12, color: kTextCtx(context),
                    fontFamily: 'monospace')),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); partagerWhatsApp(recu); },
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(context); partagerSMS(recu); },
                icon: const Icon(Icons.sms_outlined, size: 16, color: kOrange),
                label: const Text('SMS', style: TextStyle(color: kOrange)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kOrange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recu));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Reçu copié !'),
                      backgroundColor: kVert,
                      behavior: SnackBarBehavior.floating));
                },
                icon: Icon(Icons.copy, size: 16, color: kSubtextCtx(context)),
                label: Text('Copier', style: TextStyle(color: kSubtextCtx(context))),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kBorderCtx(context)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    const m = ['jan', 'fev', 'mars', 'avr', 'mai', 'juin',
                'juil', 'aout', 'sep', 'oct', 'nov', 'dec'];
    return '${d.day} ${m[d.month - 1]}. ${d.year} ${d.hour.toString().padLeft(2, "0")}h${d.minute.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final eur = TauxChangeService.fcfaVersEuros(widget.montant);
    return PopScope(
      canPop: _statut != 'pending',
      child: Scaffold(
        backgroundColor: kFondCtx(context),
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // ─── CERCLE ICÔNE ────────────────────────────
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: _statut == 'failed'
                        ? const Color(0xFFFEF0F0)
                        : _statut == 'pending'
                            ? kOrange.withValues(alpha: 0.12)
                            : const Color(0xFFE7F6EF),
                    shape: BoxShape.circle),
                child: _statut == 'pending'
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: kOrange, strokeWidth: 3))
                    : Icon(
                        _statut == 'failed' ? Icons.error_outline : Icons.check_circle,
                        color: _statut == 'failed' ? kRouge : kVert,
                        size: 48),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fade,
              child: Column(children: [
                Text(
                  _statut == 'success' ? 'Transfert réussi !'
                      : _statut == 'failed' ? 'Transfert échoué'
                      : 'Confirmation en cours...',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
                      color: _statut == 'failed' ? kRouge : kTextCtx(context))),
                const SizedBox(height: 8),
                if (_statut == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: kOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kOrange)),
                      const SizedBox(width: 8),
                      const Text('Confirme sur ton téléphone via USSD',
                          style: TextStyle(fontSize: 12, color: kOrange,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                if (_statut == 'failed')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: kRouge.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kRouge.withValues(alpha: 0.2))),
                    child: Text(
                        _erreurPayout.isNotEmpty ? _erreurPayout
                            : 'Le paiement n\'a pas été confirmé.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: kRouge,
                            fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(height: 8),
                Text('FCFA ${widget.montant}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600,
                        letterSpacing: -1, color: kNuit)),
                const SizedBox(height: 4),
                if (NumerosManager.conversionEurOn)
                  Text('~$eur EUR',
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text('Vers +228 ${widget.numero} · ${widget.operateur}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(height: 20),
            // ─── CARTE REÇU ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: kCardCtx(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorderCtx(context)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
                  ]),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Recu', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w500, color: kTextCtx(context))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _statut == 'success' ? const Color(0xFFE7F6EF)
                            : _statut == 'failed'  ? const Color(0xFFFEF0F0)
                            : const Color(0xFFFFF5EA),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        _statut == 'success' ? 'Confirmé'
                            : _statut == 'failed' ? 'Échoué' : 'En attente',
                        style: TextStyle(fontSize: 11,
                            color: _statut == 'success' ? kVert
                                : _statut == 'failed' ? kRouge : kOrange,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
                const Divider(height: 20),
                _ReceiptRow('Operateur', widget.operateur, context: context),
                _ReceiptRow('Numero', '+228 ${widget.numero}', context: context),
                _ReceiptRow('Reference', '#$_ref', context: context),
                _ReceiptRow('Montant',
                    NumerosManager.conversionEurOn
                        ? 'FCFA ${widget.montant} (~$eur EUR)'
                        : 'FCFA ${widget.montant}',
                    context: context),
                _ReceiptRow('Frais', 'FCFA ${widget.frais}', context: context),
                _ReceiptRow('Date', _fmtDate(DateTime.now()), context: context),
              ]),
            ),
            // ─── BOUTONS ─────────────────────────────────
            if (_statut == 'success') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: widget.demandeRef != null
                      ? () => launchUrl(
                          Uri.parse('https://haya.flexix.nl/pay/${widget.demandeRef}'),
                          mode: LaunchMode.externalApplication)
                      : _partagerTexte,
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Partager le reçu',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
            if (_statut == 'failed') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  label: const Text('Réessayer',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
            if (_statut == 'pending') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 48,
                child: TextButton(
                  onPressed: () async {
                    final confirmer = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Annuler le transfert ?'),
                        content: const Text(
                            'Si tu as déjà confirmé le USSD, ton compte mobile money sera quand même débité.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Rester', style: TextStyle(color: kOrange)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Quitter quand même',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    );
                    if (confirmer == true && context.mounted) {
                      Navigator.popUntil(context, (r) => r.isFirst);
                    }
                  },
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ),
            ],
            if (_statut != 'pending') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kNuit,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text("Retour a l'accueil",
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ]),
        ),
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

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _slide,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kNuit,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kOrange.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: const BoxDecoration(
                      color: Color(0xFFE7F6EF), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: kVert, size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Transfert confirme',
                      style: TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text('FCFA ${widget.montant} vers +228 ${widget.numero}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(widget.operateur,
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ),
              GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Icon(Icons.close, color: Colors.white38, size: 18)),
            ]),
          ),
        ),
      );
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final BuildContext context;
  const _ReceiptRow(this.label, this.value, {required this.context});
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: kTextCtx(context))),
        ]),
      );
}
