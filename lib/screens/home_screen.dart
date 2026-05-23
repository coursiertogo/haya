import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../services/managers.dart';
import '../services/auth_utils.dart';
import 'payment_request_screen.dart';
import 'mes_demandes_screen.dart';
import 'parametres_screen.dart';
import 'send_screen.dart';
import 'contacts_screen.dart';
import 'qr_scanner_screen.dart';
import 'demander_recevoir_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _dernieresDemandes = [];
  bool _chargement = true;
  int _aPayerCount = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final data = await HayaApiService.getDemandesEnvoyees();

    // Compteur "À payer" : local (pending_to_pay) + serveur (telephone_payeur)
    final prefs = await SharedPreferences.getInstance();
    final pendingRefs = Set<String>.from(prefs.getStringList('pending_to_pay') ?? []);
    final phones = <String>{};
    if (UserManager.telephone.isNotEmpty) phones.add(UserManager.telephone);
    if (NumerosManager.tmoney.isNotEmpty) phones.add(NumerosManager.tmoney);
    if (NumerosManager.flooz.isNotEmpty) phones.add(NumerosManager.flooz);
    for (final phone in phones) {
      final serveur = await HayaApiService.getDemandesAPayer(phone);
      for (final d in serveur) {
        if (d['statut'] == 'en_attente') pendingRefs.add(d['reference'].toString());
      }
    }

    if (mounted) setState(() {
      _dernieresDemandes = data;
      _aPayerCount = pendingRefs.length;
      _chargement = false;
    });
  }

  String _formatMontant(dynamic m) {
    final n = (double.tryParse(m.toString()) ?? 0).toInt();
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (x) => '${x[1]} ');
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Auj. ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      if (diff.inDays == 1) return 'Hier';
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'paye': return kVert;
      case 'annule': return Colors.grey;
      default: return kOrange;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'paye': return 'Payé';
      case 'annule': return 'Expiré';
      default: return 'En attente';
    }
  }

  void _afficherMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: kNuit,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.settings_outlined, color: kOrange, size: 22),
            ),
            title: const Text('Paramètres',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: Colors.white)),
            subtitle: Text('PIN, numéros, apparence',
                style: TextStyle(fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5))),
            trailing: Icon(Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4)),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.push(ctx,
                  MaterialPageRoute(builder: (_) => const ParametresScreen()));
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kRouge.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout, color: kRouge, size: 22),
            ),
            title: const Text('Déconnexion',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: kRouge)),
            onTap: () {
              Navigator.pop(sheetCtx);
              showDialog(
                context: ctx,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: kNuit,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Déconnexion',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  content: Text('Voulez-vous vraiment vous déconnecter ?',
                      style: TextStyle(fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: Text('Annuler',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5)))),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await seDeconnecter(ctx);
                      },
                      child: const Text('Déconnecter',
                          style: TextStyle(
                              color: kRouge, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aDesDemandes = _dernieresDemandes.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ─── HEADER ─────────────────────────────────
          Container(
            color: kNuit,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text('haya',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              GestureDetector(
                onTap: () => _afficherMenu(context),
                child: Row(children: [
                  // Avatar initiales
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF5568D9), Color(0xFF3B4EC8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5)),
                    child: Center(
                      child: Text(UserManager.initiales,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.6), size: 18),
                ]),
              ),
            ]),
          ),

          // ─── CONTENU ───────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              color: kOrange,
              backgroundColor: kCardCtx(context),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Salutation ──────────────────────
                    Text('Bonjour, ${UserManager.prenom} 👋',
                        style: TextStyle(color: kTextCtx(context),
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),

                    // ── Actions principales ─────────────
                    Row(children: [
                      _ActionBtn(
                        label: 'Envoyer',
                        icon: Icons.arrow_upward_rounded,
                        bg: kNuit,
                        fg: Colors.white,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SendScreen()))
                            .then((_) => _charger()),
                      ),
                      const SizedBox(width: 12),
                      _ActionBtn(
                        label: 'Demander',
                        icon: Icons.arrow_downward_rounded,
                        bg: kOrange,
                        fg: Colors.white,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PaymentRequestScreen()))
                            .then((_) => _charger()),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // ── Actions secondaires ─────────────
                    Row(children: [
                      _SmallActionBtn(
                        label: 'Scanner',
                        icon: Icons.qr_code_scanner_rounded,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const QrScannerScreen()))
                            .then((_) => _charger()),
                        context: context,
                      ),
                      const SizedBox(width: 10),
                      _SmallActionBtn(
                        label: 'Contacts',
                        icon: Icons.contacts_outlined,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ContactsScreen()))
                            .then((_) => _charger()),
                        context: context,
                      ),
                      const SizedBox(width: 10),
                      _SmallActionBtn(
                        label: 'Recevoir',
                        icon: Icons.qr_code_rounded,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const DemanderRecevoirScreen()))
                            .then((_) => _charger()),
                        context: context,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Notification à payer ────────────
                    if (_aPayerCount > 0) ...[
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const MesDemandesScreen(initialTab: 1)))
                            .then((_) => _charger()),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                              color: kOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kOrange.withValues(alpha: 0.35))),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                  color: kOrange, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text('$_aPayerCount',
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 15, fontWeight: FontWeight.w800))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_aPayerCount == 1
                                  ? '1 demande en attente de paiement'
                                  : '$_aPayerCount demandes en attente de paiement',
                                  style: const TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600, color: kOrange)),
                              const SizedBox(height: 2),
                              Text('Appuyer pour payer',
                                  style: TextStyle(fontSize: 11,
                                      color: kOrange.withValues(alpha: 0.7))),
                            ])),
                            Icon(Icons.chevron_right,
                                color: kOrange.withValues(alpha: 0.7)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Activité récente ────────────────
                    if (_chargement)
                      const Center(child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(color: kOrange, strokeWidth: 2),
                      ))
                    else if (!aDesDemandes)
                      _buildEmptyState(context)
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Activité récente',
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kSubtextCtx(context))),
                          if (_dernieresDemandes.length > 3)
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const MesDemandesScreen())),
                              child: const Text('Voir tout',
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600, color: kOrange)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._dernieresDemandes.take(5).map((d) {
                        final statut = d['statut'] ?? 'en_attente';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                              color: kCardCtx(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorderCtx(context)),
                              boxShadow: isDark ? [] : [BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8, offset: const Offset(0, 2))]),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  color: _statutColor(statut).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(
                                statut == 'paye' ? Icons.check_circle_outline
                                    : statut == 'annule' ? Icons.access_time_outlined
                                    : Icons.pending_outlined,
                                color: _statutColor(statut), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(d['objet'] ?? '',
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kTextCtx(context))),
                              const SizedBox(height: 2),
                              Text(_statutLabel(statut),
                                  style: TextStyle(fontSize: 11,
                                      color: _statutColor(statut))),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('FCFA ${_formatMontant(d['montant'])}',
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kTextCtx(context))),
                              const SizedBox(height: 2),
                              Text(_formatDate(d['cree_le']),
                                  style: TextStyle(fontSize: 11,
                                      color: kSubtextCtx(context))),
                            ]),
                          ]),
                        );
                      }),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Comment ça marche',
          style: TextStyle(
              color: kSubtextCtx(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
      const SizedBox(height: 16),
      _Etape(numero: '1', titre: 'Crée une demande',
          desc: 'Entre le montant et l\'objet'),
      const SizedBox(height: 12),
      _Etape(numero: '2', titre: 'Partage le lien',
          desc: 'Via WhatsApp, SMS ou autre'),
      const SizedBox(height: 12),
      _Etape(numero: '3', titre: 'Reçois l\'argent',
          desc: 'Le destinataire paie sans télécharger Haya'),
    ]);
  }
}

class _Etape extends StatelessWidget {
  final String numero, titre, desc;
  const _Etape({required this.numero, required this.titre, required this.desc});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kOrange.withValues(alpha: 0.3))),
        child: Center(
          child: Text(numero,
              style: const TextStyle(color: kOrange, fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre,
            style: TextStyle(
                color: kTextCtx(context),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc,
            style: TextStyle(
                color: kSubtextCtx(context),
                fontSize: 12)),
      ])),
    ],
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, fg;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.bg, required this.fg, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: bg.withValues(alpha: 0.3),
                blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: fg, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
              color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

class _SmallActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final BuildContext context;
  const _SmallActionBtn({required this.label, required this.icon,
      required this.onTap, required this.context});
  @override
  Widget build(BuildContext ctx) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: kCardCtx(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderCtx(context)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: kOrange, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
              color: kTextCtx(context),
              fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}
