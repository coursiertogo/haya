import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';
import 'contacts_screen.dart';
import 'parametres_screen.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _nombreTx = 0;
  int _totalEnvoye = 0;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final stats = await HayaApiService.getStats();
    if (mounted) {
      setState(() {
        _nombreTx = int.tryParse(stats['nombre_transactions']?.toString() ?? '0') ?? 0;
        _totalEnvoye = (double.tryParse(stats['total_envoye']?.toString() ?? '0') ?? 0).toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        title: const Text('Profil',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context))
            : null,
        automaticallyImplyLeading: false,
      ),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)])),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(children: [
            CircleAvatar(
                radius: 42,
                backgroundColor: kOrange.withValues(alpha: 0.85),
                child: Text(UserManager.initiales,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700))),
            const SizedBox(height: 14),
            Text(UserManager.nomComplet,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('+228 ${UserManager.telephone}',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ProfilStat('Transferts', '$_nombreTx'),
              Container(
                  width: 1, height: 30, color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 24)),
              _ProfilStat('Envoyé',
                  _totalEnvoye == 0 ? '—' :
                  _totalEnvoye.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')),
              Container(
                  width: 1, height: 30, color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 24)),
              _ProfilStat('Contacts', '${ContactsManager.contacts.length}'),
            ]),
          ]),
        ),
        Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
            const Text('Mes numéros',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _ProfilRow(Icons.phone_android, 'Tmoney',
                NumerosManager.tmoney.isNotEmpty
                    ? '+228 ${NumerosManager.tmoney}'
                    : 'Non défini',
                valueColor: NumerosManager.tmoney.isNotEmpty
                    ? kVert
                    : Colors.grey),
            _ProfilRow(Icons.phone_android, 'Flooz',
                NumerosManager.flooz.isNotEmpty
                    ? '+228 ${NumerosManager.flooz}'
                    : 'Non défini',
                valueColor: NumerosManager.flooz.isNotEmpty
                    ? kVert
                    : Colors.grey),
            const SizedBox(height: 20),
            const Text('Actions',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _ProfilAction(Icons.settings_outlined, 'Paramètres',
                'PIN, numéros, apparence',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ParametresScreen())).then(
                    (_) => setState(() {}))),
            _ProfilAction(Icons.people_outline, 'Contacts favoris',
                '${ContactsManager.contacts.length} contacts enregistrés',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ContactsScreen()))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await UserManager.effacer();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OnboardingScreen()),
                      (r) => false);
                },
                icon: const Icon(Icons.logout,
                    color: kRouge, size: 18),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: kRouge, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kRouge),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ProfilStat extends StatelessWidget {
  final String label, valeur;
  const _ProfilStat(this.label, this.valeur);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(valeur,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 11)),
      ]);
}

class _ProfilAction extends StatelessWidget {
  final IconData icon;
  final String titre, sousTitre;
  final VoidCallback onTap;
  const _ProfilAction(this.icon, this.titre, this.sousTitre,
      {required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: kCardCtx(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: kOrange),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kTextCtx(context))),
                    Text(sousTitre,
                        style: TextStyle(
                            fontSize: 12,
                            color: kSubtextCtx(context))),
                  ]),
            ),
            Icon(Icons.chevron_right,
                color: kSubtextCtx(context), size: 20),
          ]),
        ),
      );
}

class _ProfilRow extends StatelessWidget {
  final IconData icon;
  final String label, valeur;
  final Color? valueColor;
  const _ProfilRow(this.icon, this.label, this.valeur,
      {this.valueColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: kCardCtx(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorderCtx(context))),
        child: Row(children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14, color: kTextCtx(context)))),
          Text(valeur,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? kSubtextCtx(context))),
        ]),
      );
}
