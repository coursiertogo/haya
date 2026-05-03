import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';
import '../constants.dart';
import '../services/managers.dart';
import 'send_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<_ContactTel> _contactsTel = [];
  bool _chargement = false;
  bool _permissionRefusee = false;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _chargerContactsTel();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerContactsTel() async {
    setState(() => _chargement = true);
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() { _chargement = false; _permissionRefusee = true; });
      return;
    }
    try {
      final contacts = await fc.FlutterContacts.getContacts(withProperties: true);
      final liste = <_ContactTel>[];
      for (final c in contacts) {
        for (final phone in c.phones) {
          final clean = phone.number.replaceAll(RegExp(r'\D'), '');
          // Numéros togolais : 8 chiffres ou +228 + 8 chiffres
          String numero = '';
          if (clean.length == 8) {
            numero = clean;
          } else if (clean.startsWith('228') && clean.length == 11) {
            numero = clean.substring(3);
          }
          if (numero.isNotEmpty) {
            final op = detectOperateur(numero);
            if (op == 'tmoney' || op == 'flooz') {
              liste.add(_ContactTel(
                nom: c.displayName.isNotEmpty ? c.displayName : numero,
                numero: numero,
                operateur: op,
              ));
              break;
            }
          }
        }
      }
      liste.sort((a, b) => a.nom.compareTo(b.nom));
      setState(() { _contactsTel = liste; _chargement = false; });
    } catch (_) {
      setState(() => _chargement = false);
    }
  }

  List<_ContactTel> get _contactsFiltres {
    if (_recherche.isEmpty) return _contactsTel;
    return _contactsTel.where((c) =>
        c.nom.toLowerCase().contains(_recherche.toLowerCase()) ||
        c.numero.contains(_recherche)).toList();
  }

  void _envoyerVers(String numero) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => SendScreen(numeroInitial: numero)));
  }

  void _ajouterFavori(String nom, String numero, String operateur) {
    final existe = ContactsManager.contacts.any((c) => c.numero == numero);
    if (existe) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Déjà dans les favoris'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() {
      ContactsManager.contacts.add(Contact(
          nom: nom,
          numero: numero,
          operateur: operateur,
          colorIndex: ContactsManager.contacts.length % avatarColors.length));
    });
    ContactsManager.sauvegarder();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ajouté aux favoris !'),
        backgroundColor: kVert,
        behavior: SnackBarBehavior.floating));
  }

  void _ajouterManuellement() {
    final nomCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardCtx(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        final op = numCtrl.text.length >= 2 ? detectOperateur(numCtrl.text) : '';
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nouveau favori',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                    color: kTextCtx(ctx))),
            const SizedBox(height: 20),
            Text('Nom complet',
                style: TextStyle(fontSize: 13, color: kSubtextCtx(ctx))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: kInputCtx(ctx),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: nomCtrl,
                style: TextStyle(fontSize: 15, color: kTextCtx(ctx)),
                decoration: const InputDecoration(
                    hintText: 'Ex: Ama Kpodo', border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Numéro', style: TextStyle(fontSize: 13, color: kSubtextCtx(ctx))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: kInputCtx(ctx),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('+228', style: TextStyle(
                        fontSize: 14, color: kSubtextCtx(ctx),
                        fontWeight: FontWeight.w500))),
                Expanded(
                  child: TextField(
                    controller: numCtrl, keyboardType: TextInputType.phone,
                    maxLength: 8,
                    style: TextStyle(fontSize: 15, color: kTextCtx(ctx)),
                    decoration: const InputDecoration(
                        hintText: 'XX XX XX XX', border: InputBorder.none,
                        counterText: ''),
                    onChanged: (_) => setM(() {}),
                  ),
                ),
              ]),
            ),
            if (op == 'tmoney')
              Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text('Tmoney ✓',
                      style: const TextStyle(color: kVert, fontSize: 12))),
            if (op == 'flooz')
              Padding(padding: const EdgeInsets.only(top: 8),
                  child: const Text('Flooz ✓',
                      style: TextStyle(color: kVert, fontSize: 12))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: nomCtrl.text.isNotEmpty &&
                    numCtrl.text.length == 8 &&
                    (op == 'tmoney' || op == 'flooz')
                    ? () {
                        setState(() {
                          ContactsManager.contacts.add(Contact(
                              nom: nomCtrl.text, numero: numCtrl.text,
                              operateur: op,
                              colorIndex: ContactsManager.contacts.length %
                                  avatarColors.length));
                        });
                        ContactsManager.sauvegarder();
                        Navigator.pop(ctx);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kNuit,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Ajouter',
                    style: TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        );
      }),
    );
  }

  void _supprimerFavori(int i) => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            backgroundColor: kCardCtx(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Supprimer ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                    color: kTextCtx(context))),
            content: Text('Supprimer ${ContactsManager.contacts[i].nom} ?',
                style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.grey))),
              TextButton(
                  onPressed: () {
                    setState(() => ContactsManager.contacts.removeAt(i));
                    ContactsManager.sauvegarder();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Supprimer',
                      style: TextStyle(color: kRouge))),
            ],
          ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Contacts',
            style: TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w500)),
        actions: [
          if (_tabCtrl.index == 1)
            IconButton(
                icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                onPressed: _ajouterManuellement),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: kOrange,
          labelColor: kOrange,
          unselectedLabelColor: Colors.white54,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Téléphone'),
            Tab(text: 'Favoris'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTelephone(),
          _buildFavoris(),
        ],
      ),
    );
  }

  // ─── ONGLET TÉLÉPHONE ────────────────────────────────────
  Widget _buildTelephone() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: kOrange, strokeWidth: 2));
    }
    if (_permissionRefusee) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.contacts_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Permission refusée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: kTextCtx(context))),
            const SizedBox(height: 8),
            Text('Autorise Haya à accéder aux contacts dans les paramètres.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              style: ElevatedButton.styleFrom(backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Ouvrir les paramètres',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      );
    }
    if (_contactsTel.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucun contact avec numéro togolais détecté',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
        ]),
      );
    }
    final filtres = _contactsFiltres;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          decoration: BoxDecoration(color: kCardCtx(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderCtx(context))),
          child: TextField(
            style: TextStyle(fontSize: 14, color: kTextCtx(context)),
            decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(color: kSubtextCtx(context)),
                prefixIcon: Icon(Icons.search, color: kSubtextCtx(context), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12)),
            onChanged: (v) => setState(() => _recherche = v),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text('${filtres.length} contact${filtres.length > 1 ? 's' : ''} avec numéro togolais',
            style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtres.length,
          itemBuilder: (ctx, i) {
            final c = filtres[i];
            final ini = c.nom.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
            final colorIdx = i % avatarColors.length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCardCtx(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderCtx(context))),
              child: Row(children: [
                CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColors[colorIdx],
                    child: Text(ini, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: avatarTextColors[colorIdx]))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.nom, style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w500, color: kTextCtx(context))),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: c.operateur == 'tmoney'
                              ? const Color(0xFFEEEDFE)
                              : const Color(0xFFFAEEDA),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(c.operateur == 'tmoney' ? 'Tmoney' : 'Flooz',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                              color: c.operateur == 'tmoney' ? kNuit : const Color(0xFF854F0B))),
                    ),
                    const SizedBox(width: 6),
                    Text('+228 ${c.numero}',
                        style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
                  ]),
                ])),
                // Ajouter aux favoris
                GestureDetector(
                  onTap: () => _ajouterFavori(c.nom, c.numero, c.operateur),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.star_border, color: kOrange, size: 18)),
                ),
                const SizedBox(width: 8),
                // Envoyer
                GestureDetector(
                  onTap: () => _envoyerVers(c.numero),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: kNuit.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.send_outlined, color: kNuit, size: 18)),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ─── ONGLET FAVORIS ──────────────────────────────────────
  Widget _buildFavoris() {
    if (ContactsManager.contacts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_border, color: Colors.grey.shade300, size: 56),
          const SizedBox(height: 12),
          Text('Aucun favori', style: TextStyle(fontSize: 16, color: kSubtextCtx(context))),
          const SizedBox(height: 8),
          Text('Ajoute depuis l\'onglet Téléphone\nou manuellement avec +',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: _ajouterManuellement,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter manuellement'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kNuit, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ContactsManager.contacts.length,
      itemBuilder: (ctx, i) {
        final c = ContactsManager.contacts[i];
        final ini = c.nom.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
        final bg = avatarColors[c.colorIndex % avatarColors.length];
        final tc = avatarTextColors[c.colorIndex % avatarTextColors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCardCtx(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderCtx(context))),
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: bg,
                child: Text(ini, style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: tc))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nom, style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w500, color: kTextCtx(context))),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: c.operateur == 'tmoney'
                          ? const Color(0xFFEEEDFE)
                          : const Color(0xFFFAEEDA),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(c.operateur == 'tmoney' ? 'Tmoney' : 'Flooz',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500,
                          color: c.operateur == 'tmoney' ? kNuit : const Color(0xFF854F0B))),
                ),
                const SizedBox(width: 6),
                Text('+228 ${c.numero}',
                    style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
              ]),
            ])),
            GestureDetector(
              onTap: () => _envoyerVers(c.numero),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.send_outlined, color: kOrange, size: 20)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _supprimerFavori(i),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kRouge.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline, color: kRouge, size: 20)),
            ),
          ]),
        );
      },
    );
  }
}

class _ContactTel {
  final String nom, numero, operateur;
  const _ContactTel({required this.nom, required this.numero, required this.operateur});
}
