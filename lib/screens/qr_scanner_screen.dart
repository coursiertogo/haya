import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants.dart';
import 'send_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _traite = false;

  void _onDetect(BarcodeCapture capture) {
    if (_traite) return;
    final valeur = capture.barcodes.firstOrNull?.rawValue;
    if (valeur == null) return;
    _traite = true;

    String? numero;
    String? operateur;

    try {
      final uri = Uri.parse(valeur);
      if (uri.scheme == 'haya' && uri.host == 'send') {
        numero = uri.queryParameters['numero'];
        operateur = uri.queryParameters['operateur'];
      }
    } catch (_) {}

    // Fallback : numéro brut
    if (numero == null) {
      final clean = valeur.replaceAll(RegExp(r'\D'), '');
      if (clean.length == 8) {
        numero = clean;
      } else if (clean.length == 11 && clean.startsWith('228')) {
        numero = clean.substring(3);
      }
    }

    if (numero != null && numero.length == 8) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendScreen(
            numeroInitial: numero,
            operateurInitial: operateur,
          ),
        ),
      );
    } else {
      setState(() => _traite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: kNuit,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scanner un QR Haya',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Center(
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: kOrange, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: const Text('Pointez vers le QR code Haya',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ]),
    );
  }
}
