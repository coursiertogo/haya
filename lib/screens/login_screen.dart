import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../services/managers.dart';
import 'main_screen.dart';
import 'mot_de_passe_oublie_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _chargement = false;
  bool _voirPass = false;
  bool _voirPassConfirm = false;
  String _erreur = '';
  String _opDetecte = '';
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();

  Future<void> _connexion() async {
    if (_phoneCtrl.text.length < 8 || _passCtrl.text.isEmpty) {
      setState(() => _erreur = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = '';
    });
    try {
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/connexion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
          'mot_de_passe': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final user = data['utilisateur'];
        UserManager.nom = user['nom'] ?? '';
        UserManager.prenom = user['prenom'] ?? '';
        UserManager.telephone = user['telephone'] ?? '';
        UserManager.id = user['id'] ?? 0;
        HayaApiService.utilisateurId = user['id'];
        await UserManager.sauvegarder();
        await NumerosManager.charger();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false);
      } else {
        setState(() =>
            _erreur = data['message'] ?? 'Numero ou mot de passe incorrect.');
      }
    } catch (_) {
      setState(() => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _inscription() async {
    if (_nomCtrl.text.isEmpty ||
        _prenomCtrl.text.isEmpty ||
        _phoneCtrl.text.length < 8 ||
        _passCtrl.text.length < 4) {
      setState(() => _erreur =
          'Veuillez remplir tous les champs (mot de passe min. 4 caracteres).');
      return;
    }
    if (_passCtrl.text != _passConfirmCtrl.text) {
      setState(
          () => _erreur = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (_opDetecte != 'tmoney' && _opDetecte != 'flooz') {
      setState(() => _erreur =
          'Numero non reconnu. Utilisez un numero Tmoney ou Flooz.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = '';
    });
    try {
      final response = await http.post(
        Uri.parse('${HayaApiService.baseUrl}/auth/inscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _nomCtrl.text.trim(),
          'prenom': _prenomCtrl.text.trim(),
          'telephone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
          'mot_de_passe': _passCtrl.text,
          'pin': '0000',
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final user = data['utilisateur'];
        UserManager.nom = user['nom'] ?? '';
        UserManager.prenom = user['prenom'] ?? '';
        UserManager.telephone = user['telephone'] ?? '';
        UserManager.id = user['id'] ?? 0;
        HayaApiService.utilisateurId = user['id'];
        await UserManager.sauvegarder();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false);
      } else {
        setState(
            () => _erreur = data['message'] ?? 'Erreur inscription.');
      }
    } catch (_) {
      setState(() => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 24),
            Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: kNuit,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.arrow_upward,
                      color: kOrange, size: 26)),
              const SizedBox(width: 14),
              Text('haya',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: kTextCtx(context),
                      letterSpacing: -1)),
            ]),
            const SizedBox(height: 10),
            Text("Envoie. C'est parti.",
                style: TextStyle(
                    fontSize: 15, color: kSubtextCtx(context))),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                  color: kInputCtx(context),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() {
                          _isLogin = true;
                          _erreur = '';
                        }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: _isLogin
                              ? kCardCtx(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('Connexion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _isLogin
                                  ? kTextCtx(context)
                                  : kSubtextCtx(context))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() {
                          _isLogin = false;
                          _erreur = '';
                        }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: !_isLogin
                              ? kCardCtx(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('Inscription',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: !_isLogin
                                  ? kTextCtx(context)
                                  : kSubtextCtx(context))),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            if (!_isLogin) ...[
              Text('Nom',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderCtx(context))),
                child: TextField(
                  controller: _nomCtrl,
                  style: TextStyle(
                      fontSize: 16, color: kTextCtx(context)),
                  decoration: const InputDecoration(
                      hintText: 'Ex: Azanleko',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Prenom',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderCtx(context))),
                child: TextField(
                  controller: _prenomCtrl,
                  style: TextStyle(
                      fontSize: 16, color: kTextCtx(context)),
                  decoration: const InputDecoration(
                      hintText: 'Ex: Koami',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
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
                    style: TextStyle(
                        fontSize: 16, color: kTextCtx(context)),
                    decoration: const InputDecoration(
                        hintText: 'XX XX XX XX',
                        border: InputBorder.none,
                        counterText: ''),
                    onChanged: (v) =>
                        setState(() => _opDetecte = detectOperateur(v)),
                  ),
                ),
              ]),
            ),
            if (!_isLogin && _phoneCtrl.text.length >= 2) ...[
              const SizedBox(height: 6),
              if (_opDetecte == 'tmoney')
                const Row(children: [
                  Icon(Icons.check_circle, color: kVert, size: 14),
                  SizedBox(width: 4),
                  Text('Tmoney detecte',
                      style:
                          TextStyle(color: kVert, fontSize: 12)),
                ]),
              if (_opDetecte == 'flooz')
                const Row(children: [
                  Icon(Icons.check_circle, color: kVert, size: 14),
                  SizedBox(width: 4),
                  Text('Flooz detecte',
                      style:
                          TextStyle(color: kVert, fontSize: 12)),
                ]),
              if (_opDetecte == 'inconnu')
                const Row(children: [
                  Icon(Icons.error_outline,
                      color: kRouge, size: 14),
                  SizedBox(width: 4),
                  Text('Numero non reconnu',
                      style:
                          TextStyle(color: kRouge, fontSize: 12)),
                ]),
            ],
            const SizedBox(height: 16),
            Text('Mot de passe',
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
                        onPressed: () =>
                            setState(() => _voirPass = !_voirPass))),
              ),
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              Text('Confirmer mot de passe',
                  style: TextStyle(
                      fontSize: 13, color: kSubtextCtx(context))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: kCardCtx(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _passConfirmCtrl.text.isNotEmpty &&
                                _passCtrl.text != _passConfirmCtrl.text
                            ? kRouge
                            : kBorderCtx(context))),
                child: TextField(
                  controller: _passConfirmCtrl,
                  obscureText: !_voirPassConfirm,
                  style: TextStyle(
                      fontSize: 16, color: kTextCtx(context)),
                  decoration: InputDecoration(
                      hintText: '........',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                          icon: Icon(
                              _voirPassConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 20),
                          onPressed: () => setState(() =>
                              _voirPassConfirm = !_voirPassConfirm))),
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
                        style:
                            TextStyle(color: kVert, fontSize: 12)),
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
                    : () => _isLogin ? _connexion() : _inscription(),
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
                        _isLogin ? 'Se connecter' : 'Creer mon compte',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 18),
            Center(
                child: Text(
                    _isLogin
                        ? 'Pas encore de compte ? Inscris-toi'
                        : 'Deja un compte ? Connecte-toi',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context)))),
            if (_isLogin) ...[
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const MotDePasseOublieScreen())),
                  child: const Text('Mot de passe oublie ?',
                      style: TextStyle(
                          fontSize: 13,
                          color: kOrange,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
