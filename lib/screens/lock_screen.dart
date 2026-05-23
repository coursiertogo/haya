import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../constants.dart';
import '../services/managers.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onDeverrouille;
  // Si fourni, gère la navigation après déverrouillage (bypass Navigator.pop)
  final Future<void> Function(BuildContext)? naviguerApres;
  const LockScreen({super.key, required this.onDeverrouille, this.naviguerApres});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _erreur = false;
  bool _bioDisponible = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _verifierBiometrie();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifierBiometrie() async {
    if (!NumerosManager.biometrieOn) return;
    try {
      final disponible = await _auth.canCheckBiometrics;
      final supporte = await _auth.isDeviceSupported();
      if (mounted) setState(() => _bioDisponible = disponible && supporte);
      if (_bioDisponible) _lancerBiometrie();
    } catch (_) {}
  }

  Future<void> _lancerBiometrie() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Déverrouillez Haya avec votre empreinte',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok && mounted) {
        if (widget.naviguerApres != null) {
          await widget.naviguerApres!(context);
        } else {
          Navigator.pop(context);
          widget.onDeverrouille();
        }
      }
    } catch (_) {}
  }

  void _onChiffre(String c) {
    if (PinManager.estBloque || _pin.length >= 6) return;
    setState(() {
      _pin += c;
      _erreur = false;
    });
    if (_pin.length == 6) _valider();
  }

  void _effacer() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _valider() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (PinManager.verifierPin(_pin)) {
      if (widget.naviguerApres != null) {
        await widget.naviguerApres!(context);
      } else {
        Navigator.pop(context);
        widget.onDeverrouille();
      }
    } else {
      setState(() {
        _pin = '';
        _erreur = true;
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  String get _messageErreur {
    if (PinManager.estBloque) {
      final s = PinManager.tempsBlocage.inSeconds;
      return 'Trop de tentatives. Réessaie dans $s sec.';
    }
    final r = PinManager.tentativesRestantes;
    return r > 0 ? 'PIN incorrect. $r tentative${r > 1 ? 's' : ''} restante${r > 1 ? 's' : ''}.' : 'PIN incorrect.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kNuit,
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 60),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                  color: kOrange, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            const Text('Application verrouillée',
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              _bioDisponible
                  ? 'Empreinte ou PIN pour continuer'
                  : 'Entrez votre PIN pour continuer',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final dx = _erreur
                    ? ((_shakeAnim.value * 4).round() % 2 == 0 ? -8.0 : 8.0) *
                        (1 - _shakeAnim.value)
                    : 0.0;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? kOrange
                        : (_erreur ? kRouge : Colors.white.withValues(alpha: 0.3)),
                  ),
                )),
              ),
            ),
            if (_erreur)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_messageErreur,
                    style: const TextStyle(color: kRouge, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(children: [
                for (final row in [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['bio', '0', '⌫']
                ])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((c) => GestureDetector(
                      onTap: c == '⌫'
                          ? _effacer
                          : c == 'bio'
                              ? (_bioDisponible ? _lancerBiometrie : null)
                              : () => _onChiffre(c),
                      child: Container(
                        width: 72, height: 72,
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: c == 'bio' && !_bioDisponible
                              ? Colors.transparent
                              : c == 'bio'
                                  ? kOrange.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: c == '⌫'
                              ? const Icon(Icons.backspace_outlined,
                                  color: Colors.white, size: 22)
                              : c == 'bio'
                                  ? Icon(Icons.fingerprint,
                                      color: _bioDisponible
                                          ? kOrange
                                          : Colors.transparent,
                                      size: 30)
                                  : Text(c,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 26,
                                          fontWeight: FontWeight.w300)),
                        ),
                      ),
                    )).toList(),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
