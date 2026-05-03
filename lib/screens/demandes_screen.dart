import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/managers.dart';
import '../services/haya_api_service.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});
  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
  List<Map<String, dynamic>> _demandes = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final response = await http.get(
        Uri.parse('${HayaApiService.baseUrl}/demandes/${UserManager.id}'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _demandes = List<Map<String, dynamic>>.from(data['demandes']);
          _chargement = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _chargement = false);
  }

  String _formatMontant(dynamic m) {
    final n = double.tryParse(m.toString())?.toInt() ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (x) => '${x[1]} ');
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'paye': return kVert;
      case 'annule': return kRouge;
      default: return kOrange;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'paye': return 'Payé';
      case 'annule': return 'Annulé';
      default: return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context))
            : null,
        automaticallyImplyLeading: false,
        title: const Text('Mes demandes',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { setState(() => _chargement = true); _charger(); },
          )
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _demandes.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Aucune demande envoyée',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: kOrange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _demandes.length,
                    itemBuilder: (context, i) {
                      final d = _demandes[i];
                      final statut = d['statut'] ?? 'en_attente';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardCtx(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorderCtx(context)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(d['objet'] ?? '',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: kTextCtx(context))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statutColor(statut).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_statutLabel(statut),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _statutColor(statut))),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text('FCFA ${_formatMontant(d['montant'])}',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: kTextCtx(context))),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.phone_android, size: 13, color: kSubtextCtx(context)),
                            const SizedBox(width: 4),
                            Text('+228 ${d['telephone_destinataire']}',
                                style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_outlined, size: 13, color: kSubtextCtx(context)),
                            const SizedBox(width: 4),
                            Text(_formatDate(d['cree_le']),
                                style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
                          ]),
                          if (statut == 'paye' && d['paye_le'] != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.check_circle_outline, size: 13, color: kVert),
                              const SizedBox(width: 4),
                              Text('Payé le ${_formatDate(d['paye_le'])}',
                                  style: const TextStyle(fontSize: 12, color: kVert)),
                            ]),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
