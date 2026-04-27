import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/managers.dart';
import 'send_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  void _ajouter() {
    final nomCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardCtx(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setM) {
        final op =
            numCtrl.text.length >= 2 ? detectOperateur(numCtrl.text) : '';
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouveau contact',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: kTextCtx(context))),
                const SizedBox(height: 20),
                Text('Nom complet',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: kInputCtx(context),
                      borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: nomCtrl,
                    style: TextStyle(
                        fontSize: 15, color: kTextCtx(context)),
                    decoration: const InputDecoration(
                        hintText: 'Ex: Ama Kpodo',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Numero',
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: kInputCtx(context),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('+228',
                            style: TextStyle(
                                fontSize: 14,
                                color: kSubtextCtx(context),
                                fontWeight: FontWeight.w500))),
                    Expanded(
                      child: TextField(
                        controller: numCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 8,
                        style: TextStyle(
                            fontSize: 15, color: kTextCtx(context)),
                        decoration: const InputDecoration(
                            hintText: 'XX XX XX XX',
                            border: InputBorder.none,
                            counterText: ''),
                        onChanged: (_) => setM(() {}),
                      ),
                    ),
                  ]),
                ),
                if (op == 'tmoney')
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Tmoney',
                          style: TextStyle(color: kNuit, fontSize: 12))),
                if (op == 'flooz')
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Flooz',
                          style: TextStyle(
                              color: Color(0xFF854F0B), fontSize: 12))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nomCtrl.text.isNotEmpty &&
                          numCtrl.text.length == 8 &&
                          (op == 'tmoney' || op == 'flooz')) {
                        setState(() {
                          ContactsManager.contacts.add(Contact(
                              nom: nomCtrl.text,
                              numero: numCtrl.text,
                              operateur: op,
                              colorIndex: ContactsManager.contacts.length %
                                  avatarColors.length));
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kNuit,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Ajouter',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
        );
      }),
    );
  }

  void _supprimer(int i) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: kCardCtx(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Supprimer ?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kTextCtx(context))),
            content: Text(
                'Supprimer ${ContactsManager.contacts[i].nom} ?',
                style: TextStyle(
                    fontSize: 14, color: kSubtextCtx(context))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.grey))),
              TextButton(
                  onPressed: () {
                    setState(
                        () => ContactsManager.contacts.removeAt(i));
                    Navigator.pop(context);
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
          title: const Text('Contacts favoris',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          actions: [
            IconButton(
                icon: const Icon(Icons.person_add_outlined,
                    color: Colors.white),
                onPressed: _ajouter)
          ]),
      body: ContactsManager.contacts.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.people_outline,
                      color: Colors.grey.shade300, size: 64),
                  const SizedBox(height: 16),
                  const Text('Aucun contact favori',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                      onPressed: _ajouter,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kNuit,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)))),
                ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ContactsManager.contacts.length,
              itemBuilder: (context, i) {
                final c = ContactsManager.contacts[i];
                final ini =
                    c.nom.split(' ').map((e) => e[0]).take(2).join();
                final bg =
                    avatarColors[c.colorIndex % avatarColors.length];
                final tc = avatarTextColors[
                    c.colorIndex % avatarTextColors.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: kCardCtx(context),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: kBorderCtx(context))),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 24,
                        backgroundColor: bg,
                        child: Text(ini,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tc))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(c.nom,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: kTextCtx(context))),
                            const SizedBox(height: 3),
                            Row(children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: c.operateur == 'tmoney'
                                        ? const Color(0xFFEEEDFE)
                                        : const Color(0xFFFAEEDA),
                                    borderRadius:
                                        BorderRadius.circular(4)),
                                child: Text(
                                    c.operateur == 'tmoney'
                                        ? 'Tmoney'
                                        : 'Flooz',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: c.operateur == 'tmoney'
                                            ? kNuit
                                            : const Color(
                                                0xFF854F0B))),
                              ),
                              const SizedBox(width: 6),
                              Text('+228 ${c.numero}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: kSubtextCtx(context))),
                            ]),
                          ]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SendScreen(
                                  numeroInitial: c.numero))),
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color:
                                  kOrange.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(10)),
                          child: const Icon(Icons.send_outlined,
                              color: kOrange, size: 20)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _supprimer(i),
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color:
                                  kRouge.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(10)),
                          child: const Icon(Icons.delete_outline,
                              color: kRouge, size: 20)),
                    ),
                  ]),
                );
              }),
      floatingActionButton: ContactsManager.contacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: _ajouter,
              backgroundColor: kOrange,
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.white))
          : null,
    );
  }
}
