import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../services/managers.dart';
import '../widgets/tx_item.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'payment_request_screen.dart';
import 'contacts_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _chargerTransactions();
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
              (double.tryParse(t['montant']?.toString() ?? '0') ?? 0)
                  .toInt();
          final op = (t['operateur'] ?? '').toString();
          final dateStr = t['cree_le']?.toString() ?? '';
          DateTime dv = DateTime.now();
          try {
            dv = DateTime.parse(dateStr);
          } catch (_) {}
          final diff = DateTime.now().difference(dv);
          String dateAff;
          if (diff.inDays == 0) {
            dateAff =
                'Auj. ${dv.hour.toString().padLeft(2, '0')}:${dv.minute.toString().padLeft(2, '0')}';
          } else if (diff.inDays == 1) {
            dateAff = 'Hier';
          } else {
            dateAff =
                '${dv.day.toString().padLeft(2, '0')}/${dv.month.toString().padLeft(2, '0')}';
          }
          return {
            'i': initiales,
            'nom': '+228 $num',
            'op': op.isNotEmpty
                ? op[0].toUpperCase() + op.substring(1)
                : 'Mobile',
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

  void _afficherMenuUtilisateur(BuildContext outerContext) {
    showModalBottomSheet(
      context: outerContext,
      backgroundColor: kCardCtx(outerContext),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(
                radius: 28,
                backgroundColor:
                    kOrange.withValues(alpha: 0.2),
                child: Text(UserManager.initiales,
                    style: const TextStyle(
                        color: kOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.w600))),
            const SizedBox(width: 14),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(UserManager.nomComplet,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: kTextCtx(outerContext))),
                  const SizedBox(height: 3),
                  Text('+228 ${UserManager.telephone}',
                      style: TextStyle(
                          fontSize: 13,
                          color: kSubtextCtx(outerContext))),
                ]),
          ]),
          const SizedBox(height: 20),
          Divider(color: kBorderCtx(outerContext)),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kNuit.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_outline,
                  color: kNuit, size: 22),
            ),
            title: Text('Mon profil',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kTextCtx(outerContext))),
            subtitle: Text('Voir et modifier mon profil',
                style: TextStyle(
                    fontSize: 12,
                    color: kSubtextCtx(outerContext))),
            trailing:
                Icon(Icons.chevron_right, color: kSubtextCtx(outerContext)),
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onGoToProfile?.call();
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.settings_outlined,
                  color: kOrange, size: 22),
            ),
            title: Text('Paramètres',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kTextCtx(outerContext))),
            subtitle: Text('PIN, notifications, apparence',
                style: TextStyle(
                    fontSize: 12,
                    color: kSubtextCtx(outerContext))),
            trailing:
                Icon(Icons.chevron_right, color: kSubtextCtx(outerContext)),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                  outerContext,
                  MaterialPageRoute(
                      builder: (_) => const ParametresScreen()));
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kRouge.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout,
                  color: kRouge, size: 22),
            ),
            title: const Text('Déconnexion',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kRouge)),
            subtitle: Text('Quitter votre compte',
                style: TextStyle(
                    fontSize: 12,
                    color: kSubtextCtx(outerContext))),
            onTap: () {
              Navigator.pop(sheetContext);
              showDialog(
                  context: outerContext,
                  builder: (dialogCtx) => AlertDialog(
                        backgroundColor:
                            kCardCtx(outerContext),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)),
                        title: Text('Déconnexion',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextCtx(outerContext))),
                        content: Text(
                            'Voulez-vous vraiment vous déconnecter ?',
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    kSubtextCtx(outerContext))),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogCtx),
                              child: const Text('Annuler',
                                  style: TextStyle(
                                      color: Colors.grey))),
                          TextButton(
                            onPressed: () async {
                              await UserManager.effacer();
                              if (!outerContext.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                  outerContext,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const LoginScreen()),
                                  (r) => false);
                            },
                            child: const Text('Déconnecter',
                                style: TextStyle(
                                    color: kRouge,
                                    fontWeight:
                                        FontWeight.w600)),
                          ),
                        ],
                      ));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D0D2B), Color(0xFF1e1e6e)])),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Row(children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: kOrange,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_upward,
                        color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                const Text('haya',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5)),
              ]),
              GestureDetector(
                onTap: () => _afficherMenuUtilisateur(context),
                child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        kOrange.withValues(alpha: 0.3),
                    child: Text(UserManager.initiales,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
              ),
            ]),
            const SizedBox(height: 18),
            Text('Bonjour, ${UserManager.prenom} !',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24)),
              child: const Row(children: [
                Icon(Icons.lock_outline,
                    color: Colors.white54, size: 18),
                SizedBox(width: 10),
                Text(
                    'Connectez votre compte pour voir votre solde',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const Text('Togo · Mode local',
                style: TextStyle(
                    color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                _CompactAction(
                    icon: Icons.arrow_outward,
                    label: 'Envoyer',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SendScreen()))),
                _VertDivider(),
                _CompactAction(
                    icon: Icons.arrow_downward,
                    label: 'Recevoir',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ReceiveScreen()))),
                _VertDivider(),
                _CompactAction(
                    icon: Icons.request_page_outlined,
                    label: 'Demander',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PaymentRequestScreen()))),
                _VertDivider(),
                _CompactAction(
                    icon: Icons.people_outline,
                    label: 'Contacts',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ContactsScreen())).then(
                        (_) => setState(() {}))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Text('Transactions recentes',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kTextCtx(context))),
            GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HistoryScreen())),
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 13,
                        color: kOrange,
                        fontWeight: FontWeight.w500))),
          ]),
        ),
        Expanded(
          child: _chargement
              ? const Center(
                  child: CircularProgressIndicator(
                      color: kOrange, strokeWidth: 2))
              : _txs.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Aucune transaction',
                            style: TextStyle(
                                fontSize: 14,
                                color: kSubtextCtx(context))),
                        const SizedBox(height: 6),
                        TextButton(
                            onPressed: _chargerTransactions,
                            child: const Text('Actualiser',
                                style: TextStyle(
                                    color: kOrange))),
                      ]))
                  : RefreshIndicator(
                      color: kOrange,
                      onRefresh: _chargerTransactions,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const HistoryScreen())),
                                  child: const Text(
                                      'Voir toutes les transactions →',
                                      style: TextStyle(
                                          color: kOrange,
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w500)),
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

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white24);
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CompactAction(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: kOrange, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ]),
      );
}
