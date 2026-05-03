import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../services/managers.dart';
import '../widgets/tx_item.dart';
import 'send_screen.dart';
import 'payment_request_screen.dart';
import 'history_screen.dart';
import 'parametres_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToProfile;
  const HomeScreen({super.key, this.onGoToProfile});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _chargement = false;
  List<Map<String, dynamic>> _txs = [];
  int _totalEnvoye = 0;
  int _nombreTx = 0;

  @override
  void initState() {
    super.initState();
    _chargerTransactions();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final stats = await HayaApiService.getStats();
    if (mounted) {
      setState(() {
        _totalEnvoye = (double.tryParse(stats['total_envoye']?.toString() ?? '0') ?? 0).toInt();
        _nombreTx = int.tryParse(stats['nombre_transactions']?.toString() ?? '0') ?? 0;
      });
    }
  }

  Future<void> _chargerTransactions() async {
    setState(() => _chargement = true);
    try {
      final data = await HayaApiService.getHistorique();
      setState(() {
        _txs = data.map((t) {
          final num = t['telephone_destinataire']?.toString() ?? '';
          final initiales =
              num.length >= 2 ? num.substring(0, 2).toUpperCase() : 'TX';
          final montant =
              (double.tryParse(t['montant']?.toString() ?? '0') ?? 0).toInt();
          final op = (t['operateur'] ?? '').toString();
          final dateStr = t['cree_le']?.toString() ?? '';
          DateTime dv = DateTime.now();
          try { dv = DateTime.parse(dateStr); } catch (_) {}
          final diff = DateTime.now().difference(dv);
          String dateAff;
          if (diff.inDays == 0) {
            dateAff = 'Auj. ${dv.hour.toString().padLeft(2, '0')}:${dv.minute.toString().padLeft(2, '0')}';
          } else if (diff.inDays == 1) {
            dateAff = 'Hier';
          } else {
            dateAff = '${dv.day.toString().padLeft(2, '0')}/${dv.month.toString().padLeft(2, '0')}';
          }
          return {
            'i': initiales,
            'nom': '+228 $num',
            'op': op.isNotEmpty ? op[0].toUpperCase() + op.substring(1) : 'Mobile',
            'date': dateAff,
            'm': '-${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
            'out': true,
            'ci': 0,
            'num': num,
          };
        }).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _afficherMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: kCardCtx(ctx),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.settings_outlined, color: kOrange, size: 22),
            ),
            title: Text('Paramètres',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTextCtx(ctx))),
            subtitle: Text('PIN, numéros, apparence',
                style: TextStyle(fontSize: 12, color: kSubtextCtx(ctx))),
            trailing: Icon(Icons.chevron_right, color: kSubtextCtx(ctx)),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ParametresScreen()));
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kRouge.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout, color: kRouge, size: 22),
            ),
            title: const Text('Déconnexion',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kRouge)),
            subtitle: Text('Quitter votre compte',
                style: TextStyle(fontSize: 12, color: kSubtextCtx(ctx))),
            onTap: () {
              Navigator.pop(sheetCtx);
              showDialog(
                context: ctx,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: kCardCtx(ctx),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Déconnexion',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextCtx(ctx))),
                  content: Text('Voulez-vous vraiment vous déconnecter ?',
                      style: TextStyle(fontSize: 14, color: kSubtextCtx(ctx))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
                    TextButton(
                      onPressed: () async {
                        await UserManager.effacer();
                        if (!ctx.mounted) return;
                        Navigator.pushAndRemoveUntil(
                            ctx,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (r) => false);
                      },
                      child: const Text('Déconnecter',
                          style: TextStyle(color: kRouge, fontWeight: FontWeight.w600)),
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
    final totalFmt = _totalEnvoye == 0
        ? '—'
        : _totalEnvoye.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: Column(children: [
        // ─── HEADER ──────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF080818), Color(0xFF141430)])),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top bar
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                        color: kOrange, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                const Text('haya',
                    style: TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w600, letterSpacing: -0.5)),
              ]),
              GestureDetector(
                onTap: () => _afficherMenu(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.menu, color: Colors.white, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Stats
            Text('Bonjour, ${UserManager.prenom} !',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total envoyé via Haya',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(_totalEnvoye == 0 ? '— FCFA' : 'FCFA $totalFmt',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Transactions',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('$_nombreTx',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            // ─── DEUX CARTES CÔTE À CÔTE ─────────────────
            Row(children: [
              // Envoyer
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SendScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1A45), Color(0xFF0D0D2B)]),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kOrange.withValues(alpha: 0.25))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: kOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_outward, color: kOrange, size: 20),
                      ),
                      const SizedBox(height: 10),
                      const Text('Envoyer',
                          style: TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Tmoney ↔ Flooz',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: kOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kOrange.withValues(alpha: 0.3))),
                        child: const Text('Cross-opérateur',
                            style: TextStyle(color: kOrange, fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Demander
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentRequestScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF97316), Color(0xFFd4580a)]),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.request_page_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 10),
                      const Text('Demander',
                          style: TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Lien · payé en 1 clic',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                        child: const Text('Exclusif Haya',
                            style: TextStyle(color: Colors.white, fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ]),
        ),

        // ─── TRANSACTIONS ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Transactions récentes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: kTextCtx(context))),
            GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen())),
                child: const Text('Voir tout',
                    style: TextStyle(fontSize: 13, color: kOrange,
                        fontWeight: FontWeight.w500))),
          ]),
        ),
        Expanded(
          child: _chargement
              ? const Center(child: CircularProgressIndicator(color: kOrange, strokeWidth: 2))
              : _txs.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Aucune transaction',
                            style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
                        const SizedBox(height: 6),
                        TextButton(
                            onPressed: _chargerTransactions,
                            child: const Text('Actualiser',
                                style: TextStyle(color: kOrange))),
                      ]))
                  : RefreshIndicator(
                      color: kOrange,
                      onRefresh: _chargerTransactions,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ..._txs.take(5).map((t) => TxItemWidget(
                                initiales: t['i'],
                                nom: t['nom'],
                                operateur: t['op'],
                                date: t['date'],
                                montant: t['m'],
                                isOut: t['out'],
                                colorIndex: t['ci'],
                                numero: t['num'],
                              )),
                          if (_txs.length > 5)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const HistoryScreen())),
                                  child: const Text('Voir toutes les transactions →',
                                      style: TextStyle(color: kOrange, fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ),
                        ],
                      )),
        ),
      ]),
    );
  }
}
