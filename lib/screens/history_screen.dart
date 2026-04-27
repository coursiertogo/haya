import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/haya_api_service.dart';
import '../widgets/tx_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filtre = 'tout', _tri = 'date';
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  DateTime? _debut, _fin;
  String _nom = '', _montantQ = '';
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
              (double.tryParse(t['montant']?.toString() ?? '0') ?? 0).toInt();
          final op = (t['operateur'] ?? '').toString();
          final dateStr = t['cree_le']?.toString() ?? '';
          DateTime dv = DateTime.now();
          try {
            dv = DateTime.parse(dateStr);
          } catch (_) {}
          final now = DateTime.now();
          String dateAff;
          final diff = now.difference(dv);
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
            'mv': montant,
            'dv': dv,
            'out': true,
            'ci': 0,
            'num': num,
            'ref': t['reference'] ?? '',
          };
        }).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var l = _txs.where((t) {
      if (_filtre == 'tmoney' && t['op'] != 'Tmoney') return false;
      if (_filtre == 'flooz' && t['op'] != 'Flooz') return false;
      if (_filtre == 'envois' && t['out'] != true) return false;
      if (_filtre == 'recus' && t['out'] != false) return false;
      if (_nom.isNotEmpty &&
          !t['nom'].toString().toLowerCase().contains(_nom.toLowerCase())) {
        return false;
      }
      if (_montantQ.isNotEmpty) {
        final m = int.tryParse(_montantQ.replaceAll(' ', ''));
        if (m != null && t['mv'] != m) return false;
      }
      if (_debut != null && (t['dv'] as DateTime).isBefore(_debut!)) {
        return false;
      }
      if (_fin != null && (t['dv'] as DateTime).isAfter(_fin!)) return false;
      return true;
    }).toList();
    if (_tri == 'nom') {
      l.sort((a, b) => a['nom'].toString().compareTo(b['nom'].toString()));
    } else if (_tri == 'montant') {
      l.sort((a, b) => (b['mv'] as int).compareTo(a['mv'] as int));
    } else {
      l.sort(
          (a, b) => (b['dv'] as DateTime).compareTo(a['dv'] as DateTime));
    }
    return l;
  }

  void _date(BuildContext context, bool isD) async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: kNuit, onPrimary: Colors.white)),
            child: child!));
    if (d != null) {
      setState(() {
        if (isD) _debut = d;
        else _fin = d;
      });
    }
  }

  void _reset() => setState(() {
        _nom = '';
        _montantQ = '';
        _debut = null;
        _fin = null;
        _nomCtrl.clear();
        _montantCtrl.clear();
      });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasF = _nom.isNotEmpty ||
        _montantQ.isNotEmpty ||
        _debut != null ||
        _fin != null;
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
          backgroundColor: kNuit,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Activite',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          actions: [
            if (hasF)
              TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.clear, color: kOrange, size: 16),
                  label: const Text('Reinitialiser',
                      style: TextStyle(color: kOrange, fontSize: 12))),
            IconButton(
                icon: const Icon(Icons.refresh,
                    color: Colors.white, size: 20),
                onPressed: _chargerTransactions),
          ]),
      body: Column(children: [
        Container(
          color: kCardCtx(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FiltreBtn('Tout', 'tout', _filtre,
                  (v) => setState(() => _filtre = v)),
              _FiltreBtn('Tmoney', 'tmoney', _filtre,
                  (v) => setState(() => _filtre = v)),
              _FiltreBtn('Flooz', 'flooz', _filtre,
                  (v) => setState(() => _filtre = v)),
              _FiltreBtn('Envois', 'envois', _filtre,
                  (v) => setState(() => _filtre = v)),
              _FiltreBtn('Recus', 'recus', _filtre,
                  (v) => setState(() => _filtre = v)),
            ]),
          ),
        ),
        Container(
          color: kFondCtx(context),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Text('Trier :',
                style: TextStyle(
                    fontSize: 12, color: kSubtextCtx(context))),
            const SizedBox(width: 8),
            _TriBtn('Date', 'date', _tri,
                (v) => setState(() => _tri = v)),
            const SizedBox(width: 6),
            _TriBtn('Montant', 'montant', _tri,
                (v) => setState(() => _tri = v)),
            const SizedBox(width: 6),
            _TriBtn(
                'Nom', 'nom', _tri, (v) => setState(() => _tri = v)),
            const Spacer(),
            Text('${_filtered.length} res.',
                style: TextStyle(
                    fontSize: 11, color: kSubtextCtx(context))),
          ]),
        ),
        Container(
          color: kCardCtx(context),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _tri == 'nom'
              ? TextField(
                  controller: _nomCtrl,
                  onChanged: (v) => setState(() => _nom = v),
                  style: TextStyle(
                      fontSize: 14, color: kTextCtx(context)),
                  decoration: InputDecoration(
                      hintText: 'Rechercher par nom...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_search,
                          color: Colors.grey, size: 20),
                      suffixIcon: _nom.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.grey, size: 18),
                              onPressed: () => setState(() {
                                    _nom = '';
                                    _nomCtrl.clear();
                                  }))
                          : null,
                      filled: true,
                      fillColor: kInputCtx(context),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none)),
                )
              : _tri == 'montant'
                  ? TextField(
                      controller: _montantCtrl,
                      onChanged: (v) =>
                          setState(() => _montantQ = v),
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontSize: 14, color: kTextCtx(context)),
                      decoration: InputDecoration(
                          hintText: 'Montant exact FCFA',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(
                              Icons.monetization_on_outlined,
                              color: Colors.grey,
                              size: 20),
                          suffixIcon: _montantQ.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey, size: 18),
                                  onPressed: () => setState(() {
                                        _montantQ = '';
                                        _montantCtrl.clear();
                                      }))
                              : null,
                          filled: true,
                          fillColor: kInputCtx(context),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none)),
                    )
                  : Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _date(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                                color: kInputCtx(context),
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16,
                                  color: _debut != null
                                      ? kNuit
                                      : Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                  _debut != null
                                      ? 'De : ${_fmt(_debut!)}'
                                      : 'Date debut',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _debut != null
                                          ? kNuit
                                          : Colors.grey)),
                              if (_debut != null) ...[
                                const Spacer(),
                                GestureDetector(
                                    onTap: () => setState(
                                        () => _debut = null),
                                    child: const Icon(Icons.clear,
                                        size: 16,
                                        color: Colors.grey)),
                              ],
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _date(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                                color: kInputCtx(context),
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16,
                                  color: _fin != null
                                      ? kNuit
                                      : Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                  _fin != null
                                      ? 'A : ${_fmt(_fin!)}'
                                      : 'Date fin',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _fin != null
                                          ? kNuit
                                          : Colors.grey)),
                              if (_fin != null) ...[
                                const Spacer(),
                                GestureDetector(
                                    onTap: () =>
                                        setState(() => _fin = null),
                                    child: const Icon(Icons.clear,
                                        size: 16,
                                        color: Colors.grey)),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            _StatCard(
                'Total envoye',
                'FCFA ${_txs.where((t) => t['out'] == true).fold(0, (s, t) => s + (t['mv'] as int)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                kRouge),
            const SizedBox(width: 10),
            _StatCard('Transactions', '${_txs.length}', kNuit),
          ]),
        ),
        Expanded(
          child: _chargement
              ? const Center(
                  child: CircularProgressIndicator(
                      color: kOrange, strokeWidth: 2))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                        Icon(Icons.search_off,
                            color: Colors.grey.shade300, size: 48),
                        const SizedBox(height: 12),
                        const Text('Aucun resultat',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 6),
                        TextButton(
                            onPressed: _reset,
                            child: const Text('Reinitialiser',
                                style: TextStyle(color: kOrange))),
                      ]))
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final t = _filtered[i];
                        return TxItemWidget(
                          initiales: t['i'],
                          nom: t['nom'],
                          operateur: t['op'],
                          date: t['date'],
                          montant: t['m'],
                          isOut: t['out'],
                          colorIndex: t['ci'] ?? 0,
                          numero: t['num'] ?? '',
                        );
                      }),
        ),
      ]),
    );
  }
}

class _FiltreBtn extends StatelessWidget {
  final String label, value, current;
  final Function(String) onTap;
  const _FiltreBtn(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final a = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: a ? kNuit : kInputCtx(context),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: a ? Colors.white : kSubtextCtx(context))),
      ),
    );
  }
}

class _TriBtn extends StatelessWidget {
  final String label, value, current;
  final Function(String) onTap;
  const _TriBtn(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final a = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: a ? kOrange : kCardCtx(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: a ? kOrange : kBorderCtx(context))),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: a ? Colors.white : kSubtextCtx(context))),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, valeur;
  final Color couleur;
  const _StatCard(this.label, this.valeur, this.couleur);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kCardCtx(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderCtx(context))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: kSubtextCtx(context))),
            const SizedBox(height: 6),
            Text(valeur,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: couleur)),
          ]),
        ),
      );
}
