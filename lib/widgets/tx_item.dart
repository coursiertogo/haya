import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../screens/send_screen.dart';

class TxItemWidget extends StatelessWidget {
  final String initiales, nom, operateur, date, montant, numero;
  final bool isOut;
  final int colorIndex;
  const TxItemWidget({
    super.key,
    required this.initiales,
    required this.nom,
    required this.operateur,
    required this.date,
    required this.montant,
    required this.isOut,
    required this.numero,
    this.colorIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isTmoney = operateur == 'Tmoney';
    final bgColor = avatarColors[colorIndex % avatarColors.length];
    final textColor = avatarTextColors[colorIndex % avatarTextColors.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: kCardCtx(context),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 28,
                backgroundColor: bgColor,
                child: Text(initiales,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor))),
            const SizedBox(height: 12),
            Text(nom,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: kTextCtx(context))),
            const SizedBox(height: 4),
            Text('+228 $numero',
                style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SendScreen(numeroInitial: numero)));
                },
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text('Envoyer a nouveau a $nom',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kNuit,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _partagerRecu(context);
                },
                icon: const Icon(Icons.receipt_long_outlined,
                    size: 18, color: kOrange),
                label: const Text('Partager le recu',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kOrange)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kOrange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler',
                    style: TextStyle(color: Colors.grey))),
          ]),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.shade100))),
        child: Row(children: [
          CircleAvatar(
              radius: 22,
              backgroundColor: bgColor,
              child: Text(initiales,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: kTextCtx(context))),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: isTmoney
                              ? const Color(0xFFEEEDFE)
                              : const Color(0xFFFAEEDA),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(operateur,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isTmoney
                                  ? kNuit
                                  : const Color(0xFF854F0B))),
                    ),
                    const SizedBox(width: 6),
                    Text(date,
                        style: TextStyle(
                            fontSize: 12, color: kSubtextCtx(context))),
                  ]),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(montant,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isOut ? kRouge : kVert)),
            Icon(Icons.chevron_right, color: kSubtextCtx(context), size: 16),
          ]),
        ]),
      ),
    );
  }

  void _partagerRecu(BuildContext context) {
    final ref =
        'TG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final montantVal = montant.replaceAll(RegExp(r'[+-]'), '').trim();
    final recu = '''
🧾 REÇU HAYA
─────────────────────
${isOut ? '📤 Transfert envoyé' : '📥 Transfert reçu'}
─────────────────────
Montant   : FCFA $montantVal
Opérateur : $operateur
${isOut ? 'Destinataire' : 'Expéditeur'} : +228 $numero
Date      : $date
Référence : #$ref
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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextCtx(context))),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(12)),
            child: Text(recu,
                style: TextStyle(
                    fontSize: 12,
                    color: kTextCtx(context),
                    fontFamily: 'monospace')),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  partagerWhatsApp(recu);
                },
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
                onPressed: () {
                  Navigator.pop(context);
                  partagerSMS(recu);
                },
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
                      content: Text('Recu copie !'),
                      backgroundColor: kVert,
                      behavior: SnackBarBehavior.floating));
                },
                icon: Icon(Icons.copy, size: 16, color: kSubtextCtx(context)),
                label:
                    Text('Copier', style: TextStyle(color: kSubtextCtx(context))),
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
}
