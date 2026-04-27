import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/managers.dart';

class PinScreen extends StatefulWidget {
  final String titre, sousTitre;
  final Function(String) onSuccess;
  final bool modeDefinition;
  const PinScreen({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.onSuccess,
    this.modeDefinition = false,
  });
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '', _pinConfirm = '';
  bool _confirming = false, _error = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onChiffre(String c) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += c;
      _error = false;
    });
    if (_pin.length == 4) _valider();
  }

  void _effacer() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _valider() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (widget.modeDefinition) {
      if (!_confirming) {
        setState(() {
          _pinConfirm = _pin;
          _pin = '';
          _confirming = true;
        });
      } else {
        if (_pin == _pinConfirm) {
          await PinManager.definirPin(_pin);
          widget.onSuccess(_pin);
        } else {
          setState(() {
            _pin = '';
            _error = true;
            _confirming = false;
            _pinConfirm = '';
          });
          _shakeCtrl.forward(from: 0);
        }
      }
    } else {
      if (PinManager.verifierPin(_pin)) {
        widget.onSuccess(_pin);
      } else {
        setState(() {
          _pin = '';
          _error = true;
        });
        _shakeCtrl.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titre =
        widget.modeDefinition && _confirming ? 'Confirmer le PIN' : widget.titre;
    final sousTitre = widget.modeDefinition && _confirming
        ? 'Retape le meme PIN'
        : widget.sousTitre;
    return Scaffold(
      backgroundColor: kNuit,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: kOrange, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 24),
          Text(titre,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(sousTitre,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) {
              final dx = _error
                  ? ((_shakeAnim.value * 4).round() % 2 == 0 ? -8.0 : 8.0) *
                      (1 - _shakeAnim.value)
                  : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? kOrange
                        : (_error
                            ? kRouge
                            : Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ),
          if (_error)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('PIN incorrect. Reessaie.',
                  style: TextStyle(color: kRouge, fontSize: 13)),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
            child: Column(children: [
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['', '0', '⌫']
              ])
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row
                      .map((c) => GestureDetector(
                            onTap: c == '⌫'
                                ? _effacer
                                : c.isEmpty
                                    ? null
                                    : () => _onChiffre(c),
                            child: Container(
                              width: 72,
                              height: 72,
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: c.isEmpty
                                      ? Colors.transparent
                                      : Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: c == '⌫'
                                    ? const Icon(Icons.backspace_outlined,
                                        color: Colors.white, size: 22)
                                    : Text(c,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w300)),
                              ),
                            ),
                          ))
                      .toList(),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
