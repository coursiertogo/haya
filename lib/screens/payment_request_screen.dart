import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';
import 'parametres_screen.dart';

class PaymentRequestScreen extends StatefulWidget {
  const PaymentRequestScreen({super.key});
  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final _montantCtrl = TextEditingController();
  final _objetCtrl = TextEditingController();
  int _etape = 1;
  bool _chargement = false;
  String _opReception = '';

  bool get _deuxComptes =>
      NumerosManager.tmoney.isNotEmpty && NumerosManager.flooz.isNotEmpty;
  int get _totalEtapes => _deuxComptes ? 3 : 2;

  final List<int> _montantsSuggeres = [
    500, 1000, 2500, 5000, 10000, 25000, 50000
  ];
  final List<String> _objetsSuggeres = [
    'Loyer', 'Courses', 'Transport', 'Remboursement',
    'Cadeau', 'Restaurant', 'Facture'
  ];

  @override
  void initState() {
    super.initState();
    // Pré-sélectionner le premier compte disponible
    _opReception = NumerosManager.tmoney.isNotEmpty ? 'tmoney' : 'flooz';
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _objetCtrl.dispose();
    super.dispose();
  }

  int get _montant => int.tryParse(_montantCtrl.text.replaceAll(' ', '')) ?? 0;
  bool get _peutContinuer => _montant > 0;
  bool get _peutCreer =>
      _montant > 0 &&
      _objetCtrl.text.trim().isNotEmpty &&
      (NumerosManager.tmoney.isNotEmpty || NumerosManager.flooz.isNotEmpty);

  Future<void> _creerEtPartager() async {
    if (!_peutCreer || _chargement) return;
    setState(() => _chargement = true);

    final ref = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
    final op = _opReception;
    final tel = op == 'tmoney' ? NumerosManager.tmoney : NumerosManager.flooz;

    if (UserManager.id <= 1 || HayaApiService.token.isEmpty) {
      final result = await HayaApiService.inscrireUtilisateur(
        prenom: UserManager.prenom,
        telephone: UserManager.telephone,
      );
      if (result != null) {
        UserManager.id = result['id'] ?? UserManager.id;
        HayaApiService.utilisateurId = UserManager.id;
        await UserManager.sauvegarder();
      }
    }

    final ok = await HayaApiService.creerDemande(
      telephone: tel,
      montant: _montant,
      objet: _objetCtrl.text.trim(),
      operateur: op,
      reference: ref,
    );

    if (!mounted) return;
    setState(() => _chargement = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur de connexion. Réessaie.'),
          backgroundColor: kRouge,
          behavior: SnackBarBehavior.floating));
      return;
    }

    final lien = 'https://haya.flexix.nl/pay/$ref?preview=1';
    launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_etape > 1) {
              setState(() => _etape--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('Nouvelle demande — $_etape/$_totalEtapes',
            style: const TextStyle(color: Color(0xFF111827), fontSize: 16,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _etape / _totalEtapes,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
          ),
        ),
      ),
      body: _etape == 1
          ? _buildEtape1()
          : _etape == 2
              ? _buildEtape2()
              : _buildEtape3(),
    );
  }

  // ─── ÉTAPE 1 : Montant ───────────────────────────────
  Widget _buildEtape1() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('Combien veux-tu recevoir ?',
            style: TextStyle(color: Color(0xFF111827), fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 28),
        // Champ montant
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('FCFA',
                  style: TextStyle(color: Color(0xFF6B7280),
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: TextField(
                controller: _montantCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF111827), fontSize: 28,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 28),
                    border: InputBorder.none),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Suggestions
        Text('Suggestions rapides',
            style: const TextStyle(color: Color(0xFF6B7280),
                fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _montantsSuggeres.map((m) {
          final fmt = m.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (x) => '${x[1]} ');
          return GestureDetector(
            onTap: () => setState(() => _montantCtrl.text = m.toString()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: _montant == m
                      ? kOrange
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _montant == m
                          ? kOrange
                          : const Color(0xFFE5E7EB))),
              child: Text('$fmt F',
                  style: TextStyle(
                      color: _montant == m ? Colors.white : const Color(0xFF374151),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList()),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _peutContinuer
                ? () => setState(() => _etape = 2)
                : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: const Text('Suivant →',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ─── ÉTAPE 2 : Objet + Partager ──────────────────────
  Widget _buildEtape2() {
    if (UserManager.nomComplet.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_outline, size: 56, color: kOrange),
            const SizedBox(height: 16),
            const Text('Ton nom est requis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: Color(0xFF111827))),
            const SizedBox(height: 10),
            const Text('Ton nom apparaît sur les demandes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ParametresScreen(ouvrirNumeros: true)))
                  .then((_) => setState(() {})),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Compléter mon profil',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      );
    }

    if (NumerosManager.tmoney.isEmpty && NumerosManager.flooz.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.phone_android, size: 56, color: kOrange),
            const SizedBox(height: 16),
            const Text('Aucun numéro enregistré',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: Color(0xFF111827))),
            const SizedBox(height: 10),
            const Text('Ajoute ton numéro Tmoney/Flooz dans Paramètres pour recevoir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ParametresScreen(ouvrirNumeros: true)))
                  .then((_) => setState(() {})),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Aller dans Paramètres',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('Pour quoi ?',
            style: TextStyle(color: Color(0xFF111827), fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // Aperçu montant
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOrange.withValues(alpha: 0.3))),
          child: Row(children: [
            const Icon(Icons.attach_money, color: kOrange, size: 18),
            const SizedBox(width: 8),
            Text(
              'FCFA ${_montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
              style: const TextStyle(color: kOrange, fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Champ objet
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: _objetCtrl,
            autofocus: true,
            style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
            decoration: const InputDecoration(
                hintText: 'Loyer, courses, transport...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14)),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        // Suggestions objet
        Wrap(spacing: 8, runSpacing: 8, children: _objetsSuggeres.map((o) {
          final selected = _objetCtrl.text == o;
          return GestureDetector(
            onTap: () => setState(() => _objetCtrl.text = o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: selected
                      ? kOrange
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected
                          ? kOrange
                          : Colors.white.withValues(alpha: 0.2))),
              child: Text(o,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList()),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _peutCreer && !_chargement
                ? () {
                    if (_deuxComptes) {
                      setState(() => _etape = 3);
                    } else {
                      _creerEtPartager();
                    }
                  }
                : null,
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text(_deuxComptes ? 'Suivant →' : 'Créer et partager',
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ─── ÉTAPE 3 : Compte de réception ───────────────────
  Widget _buildEtape3() {
    final montantFmt = _montant.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('Recevoir sur quel compte ?',
            style: TextStyle(color: Color(0xFF111827), fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Le payeur sera obligé d\'utiliser le même opérateur.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 28),

        // Aperçu récap
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOrange.withValues(alpha: 0.25))),
          child: Row(children: [
            const Icon(Icons.receipt_outlined, color: kOrange, size: 18),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_objetCtrl.text,
                  style: const TextStyle(fontSize: 13, color: kOrange,
                      fontWeight: FontWeight.w600)),
              Text('FCFA $montantFmt',
                  style: const TextStyle(fontSize: 16, color: kOrange,
                      fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        // Sélecteur compte
        if (NumerosManager.tmoney.isNotEmpty)
          _CompteCard(
            operateur: 'tmoney',
            nom: 'Tmoney (Mixx by Yas)',
            numero: '+228 ${NumerosManager.tmoney}',
            couleur: kNuit,
            isSelected: _opReception == 'tmoney',
            onTap: () => setState(() => _opReception = 'tmoney'),
          ),
        if (NumerosManager.tmoney.isNotEmpty && NumerosManager.flooz.isNotEmpty)
          const SizedBox(height: 12),
        if (NumerosManager.flooz.isNotEmpty)
          _CompteCard(
            operateur: 'flooz',
            nom: 'Flooz (Moov Africa)',
            numero: '+228 ${NumerosManager.flooz}',
            couleur: const Color(0xFF854F0B),
            isSelected: _opReception == 'flooz',
            onTap: () => setState(() => _opReception = 'flooz'),
          ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: !_chargement ? _creerEtPartager : null,
            icon: _chargement
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.share_outlined, size: 20),
            label: Text(_chargement ? 'Création...' : 'Créer et partager',
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _CompteCard extends StatelessWidget {
  final String operateur, nom, numero;
  final Color couleur;
  final bool isSelected;
  final VoidCallback onTap;
  const _CompteCard({
    required this.operateur, required this.nom, required this.numero,
    required this.couleur, required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isSelected ? couleur : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? couleur : const Color(0xFFE5E7EB),
              width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: couleur.withValues(alpha: 0.25),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : []),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: OpLogo(operateur: operateur, height: 26),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(numero, style: TextStyle(
              fontSize: 13,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.8)
                  : const Color(0xFF6B7280))),
        ])),
        if (isSelected)
          const Icon(Icons.check_circle, color: Colors.white, size: 22),
      ]),
    ),
  );
}
