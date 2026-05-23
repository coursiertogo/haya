import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants.dart';
import '../services/managers.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String _op = '';

  @override
  void initState() {
    super.initState();
    // Sélectionner l'opérateur par défaut selon les numéros enregistrés
    if (NumerosManager.tmoney.isNotEmpty) {
      _op = 'tmoney';
    } else if (NumerosManager.flooz.isNotEmpty) {
      _op = 'flooz';
    }
  }

  String get _num => _op == 'tmoney'
      ? NumerosManager.tmoney
      : NumerosManager.flooz;
  String get _nomOp =>
      _op == 'tmoney' ? 'Mixx by Yas (Tmoney)' : 'Flooz (Moov Africa)';

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
      body: _op.isEmpty
          ? Center(
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
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: kOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Aller dans Paramètres',
                        style: TextStyle(color: Colors.white)),
                  ),
                ]),
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Onglets opérateurs — seulement ceux enregistrés
          if (NumerosManager.tmoney.isNotEmpty && NumerosManager.flooz.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: kInputCtx(context),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _OperateurTab(
                  label: 'Tmoney',
                  isActive: _op == 'tmoney',
                  couleur: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF9B96E8)
                      : const Color(0xFF3C3489),
                  onTap: () => setState(() => _op = 'tmoney')),
              _OperateurTab(
                  label: 'Flooz',
                  isActive: _op == 'flooz',
                  couleur: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFD4924A)
                      : const Color(0xFF854F0B),
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
              QrImageView(
                data: 'haya://send?numero=$_num&operateur=$_op',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: _op == 'tmoney'
                      ? const Color(0xFF3C3489)
                      : const Color(0xFF854F0B),
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: _op == 'tmoney'
                      ? const Color(0xFF3C3489)
                      : const Color(0xFF854F0B),
                ),
              ),
              const SizedBox(height: 20),
              Text('+228 $_num',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: kTextCtx(context))),
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
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '+228 $_num'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Numéro copié !'),
                    backgroundColor: kVert,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copier le numéro',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNuit,
                  foregroundColor: Colors.white,
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

