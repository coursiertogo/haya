import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../services/managers.dart';
import 'send_screen.dart';
import 'parametres_screen.dart';

class MesDemandesScreen extends StatefulWidget {
  final int initialTab;
  const MesDemandesScreen({super.key, this.initialTab = 0});
  @override
  State<MesDemandesScreen> createState() => _MesDemandesScreenState();
}

class _MesDemandesScreenState extends State<MesDemandesScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Map<String, dynamic>> _envoyees = [];
  List<Map<String, dynamic>> _recues = [];
  bool _chargement = true;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    WidgetsBinding.instance.addObserver(this);
    _charger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final envoyees = await HayaApiService.getDemandesEnvoyees();
    final List<Map<String, dynamic>> recues = [];

    // 1. Demandes ciblées côté serveur (telephone_payeur)
    final phones = <String>{};
    if (UserManager.telephone.isNotEmpty) phones.add(UserManager.telephone);
    if (NumerosManager.tmoney.isNotEmpty) phones.add(NumerosManager.tmoney);
    if (NumerosManager.flooz.isNotEmpty) phones.add(NumerosManager.flooz);
    for (final phone in phones) {
      final r = await HayaApiService.getDemandesAPayer(phone);
      for (final d in r) {
        if (!recues.any((e) => e['reference'] == d['reference'])) recues.add(d);
      }
    }

    // 2. Demandes ouvertes via lien (pending_to_pay local)
    final prefs = await SharedPreferences.getInstance();
    final pendingRefs = prefs.getStringList('pending_to_pay') ?? [];
    final aSupprimer = <String>[];
    for (final ref in pendingRefs) {
      if (recues.any((e) => e['reference'] == ref)) continue;
      final statut = await HayaApiService.getStatutDemande(ref);
      if (statut == 'annule') {
        aSupprimer.add(ref);
        continue;
      }
      final detail = prefs.getString('pending_detail_$ref') ?? '|||';
      final parts = detail.split('|');
      recues.add({
        'reference': ref,
        'telephone_destinataire': parts.isNotEmpty ? parts[0] : '',
        'montant': parts.length > 1 ? parts[1] : '0',
        'operateur': parts.length > 2 ? parts[2] : '',
        'objet': parts.length > 3 ? parts[3] : '',
        'statut': statut,
        'cree_le': null,
        'nom_expediteur': '',
      });
    }
    if (aSupprimer.isNotEmpty) {
      final liste = prefs.getStringList('pending_to_pay') ?? [];
      liste.removeWhere(aSupprimer.contains);
      await prefs.setStringList('pending_to_pay', liste);
      for (final ref in aSupprimer) await prefs.remove('pending_detail_$ref');
    }

    recues.sort((a, b) {
      const ordre = {'en_attente': 0, 'paye': 1, 'annule': 2};
      final sa = ordre[a['statut']] ?? 1;
      final sb = ordre[b['statut']] ?? 1;
      if (sa != sb) return sa.compareTo(sb);
      return (b['cree_le'] ?? '').compareTo(a['cree_le'] ?? '');
    });
    if (mounted) {
      setState(() { _envoyees = envoyees; _recues = recues; _chargement = false; });
    }
  }

  int get _totalRecu => _envoyees
      .where((d) => d['statut'] == 'paye')
      .fold(0, (s, d) => s + ((double.tryParse(d['montant']?.toString() ?? '0') ?? 0).toInt()));

  int get _enAttenteRecues => _recues.where((d) => d['statut'] == 'en_attente').length;

  String _fmt(dynamic m) {
    final n = (double.tryParse(m.toString()) ?? 0).toInt();
    return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (x) => '${x[1]} ');
  }

  String _fmtDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Auj. ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      if (diff.inDays == 1) return 'Hier';
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  Color _sColor(String s) {
    if (s == 'paye') return kVert;
    if (s == 'annule') return Colors.grey;
    return kOrange;
  }

  String _sLabel(String s) {
    if (s == 'paye') return 'Payé';
    if (s == 'annule') return 'Expiré';
    return 'En attente';
  }

  void _payer(Map<String, dynamic> d) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SendScreen(
        numeroInitial: d['telephone_destinataire'] ?? '',
        montantInitial: (double.tryParse(d['montant']?.toString() ?? '0') ?? 0).toInt(),
        operateurInitial: d['operateur'],
        objetInitial: d['objet'],
        refInitial: d['reference'],
      ),
    )).then((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Mes demandes',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger)],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: kOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: '💰 À recevoir'),
            Tab(text: _enAttenteRecues > 0 ? '💳 À payer ($_enAttenteRecues)' : '💳 À payer'),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: _StatCard(titre: 'Total reçu',
                      valeur: 'FCFA ${_fmt(_totalRecu)}', icon: Icons.trending_up, couleur: kVert)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(titre: 'À payer',
                      valeur: '$_enAttenteRecues en attente', icon: Icons.payment_outlined, couleur: kOrange)),
                ]),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildListe(_envoyees, isRecue: false),
                    _buildListe(_recues, isRecue: true),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _buildListe(List<Map<String, dynamic>> liste, {required bool isRecue}) {
    if (liste.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Aucune demande', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        if (isRecue && NumerosManager.tmoney.isEmpty && NumerosManager.flooz.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
            child: Text('Ajoutez vos numéros Tmoney/Flooz pour voir les demandes reçues.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kSubtextCtx(context), fontSize: 13)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ParametresScreen(ouvrirNumeros: true)),
            ).then((_) => _charger()),
            icon: const Icon(Icons.add, color: kOrange, size: 18),
            label: const Text('Ajouter mes numéros', style: TextStyle(color: kOrange, fontWeight: FontWeight.w600)),
          ),
        ],
      ]));
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: kOrange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: liste.length,
        itemBuilder: (_, i) {
          final d = liste[i];
          final statut = d['statut'] ?? 'en_attente';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kCardCtx(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: statut == 'en_attente' && isRecue
                        ? kOrange.withValues(alpha: 0.4) : kBorderCtx(context)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (isRecue && (d['nom_expediteur'] ?? '').toString().trim().isNotEmpty)
                    Text(d['nom_expediteur'].toString().trim(),
                        style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
                  Text(d['objet'] ?? '', style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: kTextCtx(context))),
                  const SizedBox(height: 2),
                  Text('FCFA ${_fmt(d['montant'])}', style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w700, color: kTextCtx(context))),
                  const SizedBox(height: 4),
                  Text(_fmtDate(d['cree_le']),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _sColor(statut).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_sLabel(statut), style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: _sColor(statut))),
                ),
              ]),
              if (isRecue && statut == 'en_attente') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _payer(d),
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('Payer maintenant',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
              if (isRecue && statut == 'paye') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse('https://haya.flexix.nl/pay/${d['reference']}'),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16, color: kVert),
                    label: const Text('Partager le reçu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kVert)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kVert.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titre, valeur;
  final IconData icon;
  final Color couleur;
  const _StatCard({required this.titre, required this.valeur, required this.icon, required this.couleur});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: kCardCtx(context), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderCtx(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: couleur, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(valeur, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: kTextCtx(context))),
      ])),
    ]),
  );
}
