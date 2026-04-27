import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../services/managers.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String _op = 'tmoney';
  String get _num => _op == 'tmoney' ? '90123456' : '94123456';
  String get _nomOp =>
      _op == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';
  String _msg() =>
      'Envoie-moi de l\'argent sur Haya !\n\nNom : ${UserManager.nomComplet}\nNumero $_nomOp : +228 $_num\n\nTelecharge Haya : https://play.google.com/store/apps/details?id=com.flexix.haya';

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
          title: const Text('Recevoir',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _OperateurTab(
                  label: 'Tmoney',
                  isActive: _op == 'tmoney',
                  couleur: const Color(0xFF3C3489),
                  onTap: () => setState(() => _op = 'tmoney')),
              _OperateurTab(
                  label: 'Flooz',
                  isActive: _op == 'flooz',
                  couleur: const Color(0xFF854F0B),
                  onTap: () => setState(() => _op = 'flooz')),
            ]),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: kCardCtx(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4))
                ]),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: _op == 'tmoney'
                        ? const Color(0xFFEEEDFE)
                        : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_nomOp,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _op == 'tmoney'
                            ? const Color(0xFF3C3489)
                            : const Color(0xFF854F0B))),
              ),
              const SizedBox(height: 20),
              CustomPaint(
                  size: const Size(200, 200),
                  painter: _QRCodePainter(
                      data: '+228$_num',
                      color: _op == 'tmoney'
                          ? const Color(0xFF3C3489)
                          : const Color(0xFF854F0B))),
              const SizedBox(height: 20),
              Text('+228 $_num',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: kNuit)),
              const SizedBox(height: 4),
              Text(UserManager.nomComplet,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '+228 $_num'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Numero copie !'),
                    backgroundColor: kVert,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copier le numero',
                  style: TextStyle(
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
            child: ElevatedButton.icon(
              onPressed: () => partagerWhatsApp(_msg()),
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('Partager via WhatsApp',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
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
              onPressed: () => partagerSMS(_msg()),
              icon: const Icon(Icons.sms_outlined,
                  size: 18, color: kOrange),
              label: const Text('Partager via SMS',
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
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _OperateurTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color couleur;
  final VoidCallback onTap;
  const _OperateurTab(
      {required this.label,
      required this.isActive,
      required this.couleur,
      required this.onTap});
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive ? couleur : Colors.grey)),
          ),
        ),
      );
}

class _QRCodePainter extends CustomPainter {
  final String data;
  final Color color;
  const _QRCodePainter({required this.data, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final bg = Paint()..color = Colors.white;
    final c = size.width / 21;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
    final hash =
        data.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0xFFFFFF);
    void corner(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x * c, y * c, 7 * c, 7 * c), p);
      canvas.drawRect(
          Rect.fromLTWH((x + 1) * c, (y + 1) * c, 5 * c, 5 * c), bg);
      canvas.drawRect(
          Rect.fromLTWH((x + 2) * c, (y + 2) * c, 3 * c, 3 * c), p);
    }

    corner(0, 0);
    corner(14, 0);
    corner(0, 14);
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        if ((i < 8 && j < 8) || (i > 12 && j < 8) || (i < 8 && j > 12)) {
          continue;
        }
        if (i == 6 || j == 6) {
          if ((i + j) % 2 == 0) {
            canvas.drawRect(
                Rect.fromLTWH(i * c + 1, j * c + 1, c - 2, c - 2), p);
          }
          continue;
        }
        if ((hash >> ((i * 21 + j) % 24)) & 1 == 1) {
          canvas.drawRect(
              Rect.fromLTWH(i * c + 1, j * c + 1, c - 2, c - 2), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QRCodePainter old) =>
      old.data != data || old.color != color;
}
