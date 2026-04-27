import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/haya_api_service.dart';

class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});
  @override
  State<MotDePasseOublieScreen> createState() =>
      _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  int _etape = 1;
  bool _chargement = false;
  String _erreur = '';
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _voirPass = false;

  Future<void> _envoyerOTP() async {
    if (_phoneCtrl.text.length < 8) {
      setState(
          () => _erreur = 'Entrez votre numero de telephone.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = '';
    });
    try {
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'telephone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _etape = 2);
      } else {
        setState(() => _erreur = data['message'] ?? 'Numero non trouve.');
      }
    } catch (_) {
      setState(() => _etape = 2);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _verifierOTP() async {
    if (_otpCtrl.text.length < 4) {
      setState(() => _erreur = 'Entrez le code recu par SMS.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = '';
    });
    try {
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/verifier-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
          'otp': _otpCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _etape = 3);
      } else {
        setState(() => _erreur = data['message'] ?? 'Code incorrect.');
      }
    } catch (_) {
      setState(() => _etape = 3);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _reinitialiserMotDePasse() async {
    if (_passCtrl.text.length < 4) {
      setState(
          () => _erreur = 'Mot de passe min. 4 caracteres.');
      return;
    }
    if (_passCtrl.text != _passConfirmCtrl.text) {
      setState(
          () => _erreur = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = '';
    });
    try {
      final response = await http.post(
        Uri.parse(
            '${HayaApiService.baseUrl}/auth/reinitialiser-mot-de-passe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
          'otp': _otpCtrl.text,
          'nouveau_mot_de_passe': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Mot de passe reinitialise ! Connectez-vous.'),
            backgroundColor: kVert,
            behavior: SnackBarBehavior.floating));
      } else {
        final data = jsonDecode(response.body);
        setState(() =>
            _erreur = data['message'] ?? 'Erreur reinitialisation.');
      }
    } catch (_) {
      setState(
          () => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        foregroundColor: Colors.white,
        title: const Text('Mot de passe oublie',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 16),
            Row(children: [
              _EtapeIndicateur(
                  numero: 1, label: 'Telephone', actif: _etape >= 1),
              Expanded(
                  child: Container(
                      height: 2,
                      color: _etape >= 2
                          ? kOrange
                          : kBorderCtx(context))),
              _EtapeIndicateur(
                  numero: 2, label: 'Code SMS', actif: _etape >= 2),
              Expanded(
                  child: Container(
                      height: 2,
                      color: _etape >= 3
                          ? kOrange
                          : kBorderCtx(context))),
              _EtapeIndicateur(
                  numero: 3,
                  label: 'Nouveau MDP',
                  actif: _etape >= 3),
            ]),
            const SizedBox(height: 32),
            if (_etape == 1) ...[
              Text('Votre numero de telephone',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextCtx(context))),
              const SizedBox(height: 8),
              Text(
                  'Nous allons envoyer un code SMS pour verifier votre identite.',
                  style: TextStyle(
                      fontSize: 14, color: kSubtextCtx(context))),
              const SizedBox(height: 24),
              Text('Numero',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderCtx(context))),
                child: Row(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14),
                      child: Text('+228',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kSubtextCtx(context)))),
                  Expanded(
                      child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                        fontSize: 16, color: kTextCtx(context)),
                    decoration: const InputDecoration(
                        hintText: 'XX XX XX XX',
                        border: InputBorder.none),
                  )),
                ]),
              ),
            ],
            if (_etape == 2) ...[
              Text('Code de verification',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextCtx(context))),
              const SizedBox(height: 8),
              Text(
                  'Entrez le code a 6 chiffres envoye au +228 ${_phoneCtrl.text}',
                  style: TextStyle(
                      fontSize: 14, color: kSubtextCtx(context))),
              const SizedBox(height: 24),
              Text('Code SMS',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderCtx(context))),
                child: TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextCtx(context),
                      letterSpacing: 8),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      hintText: '------',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                  child: GestureDetector(
                onTap: _envoyerOTP,
                child: const Text('Renvoyer le code',
                    style: TextStyle(
                        fontSize: 13,
                        color: kOrange,
                        fontWeight: FontWeight.w500)),
              )),
            ],
            if (_etape == 3) ...[
              Text('Nouveau mot de passe',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextCtx(context))),
              const SizedBox(height: 8),
              Text('Choisissez un nouveau mot de passe securise.',
                  style: TextStyle(
                      fontSize: 14, color: kSubtextCtx(context))),
              const SizedBox(height: 24),
              Text('Nouveau mot de passe',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderCtx(context))),
                child: TextField(
                  controller: _passCtrl,
                  obscureText: !_voirPass,
                  style: TextStyle(
                      fontSize: 16, color: kTextCtx(context)),
                  decoration: InputDecoration(
                      hintText: '........',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                          icon: Icon(
                              _voirPass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 20),
                          onPressed: () => setState(
                              () => _voirPass = !_voirPass))),
                ),
              ),
              const SizedBox(height: 16),
              Text('Confirmer',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _passConfirmCtrl.text.isNotEmpty &&
                                _passCtrl.text !=
                                    _passConfirmCtrl.text
                            ? kRouge
                            : kBorderCtx(context))),
                child: TextField(
                  controller: _passConfirmCtrl,
                  obscureText: true,
                  style: TextStyle(
                      fontSize: 16, color: kTextCtx(context)),
                  decoration: const InputDecoration(
                      hintText: '........',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_passConfirmCtrl.text.isNotEmpty &&
                  _passCtrl.text == _passConfirmCtrl.text)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: kVert, size: 14),
                    SizedBox(width: 4),
                    Text('Mots de passe identiques',
                        style: TextStyle(
                            color: kVert, fontSize: 12)),
                  ]),
                ),
            ],
            if (_erreur.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF0F0),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: kRouge, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_erreur,
                          style: const TextStyle(
                              color: kRouge, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _chargement
                    ? null
                    : () {
                        if (_etape == 1) _envoyerOTP();
                        else if (_etape == 2) _verifierOTP();
                        else _reinitialiserMotDePasse();
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: kNuit,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _etape == 1
                            ? 'Envoyer le code SMS'
                            : _etape == 2
                                ? 'Verifier le code'
                                : 'Reinitialiser le mot de passe',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EtapeIndicateur extends StatelessWidget {
  final int numero;
  final String label;
  final bool actif;
  const _EtapeIndicateur(
      {required this.numero, required this.label, required this.actif});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actif ? kOrange : kBorderCtx(context)),
          child: Center(
              child: Text('$numero',
                  style: TextStyle(
                      color: actif ? Colors.white : kSubtextCtx(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: actif ? kOrange : kSubtextCtx(context))),
      ]);
}
