import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/managers.dart';
import 'pin_screen.dart';
import 'login_screen.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});
  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _tmoneyCtrl = TextEditingController();
  final _floozCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tmoneyCtrl.text = NumerosManager.tmoney;
    _floozCtrl.text = NumerosManager.flooz;
    _nomCtrl.text = UserManager.nomComplet;
  }

  @override
  void dispose() {
    _tmoneyCtrl.dispose();
    _floozCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Paramètres',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── MON PROFIL ──────────────────────────────
          _Section(
            icon: Icons.person_outline,
            titre: 'Mon profil',
            couleur: kOrange,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: kInputCtx(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBorderCtx(context))),
                      child: TextField(
                        controller: _nomCtrl,
                        style: TextStyle(fontSize: 14, color: kTextCtx(context)),
                        decoration: InputDecoration(
                            hintText: 'Nom ou entreprise',
                            hintStyle: TextStyle(color: kSubtextCtx(context)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final nom = _nomCtrl.text.trim();
                      if (nom.isEmpty) return;
                      UserManager.prenom = nom;
                      UserManager.nom = '';
                      await UserManager.sauvegarder();
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
                          content: Text('Nom mis à jour !'),
                          backgroundColor: kVert,
                          behavior: SnackBarBehavior.floating));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12)),
                    child: const Text('OK',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── OPÉRATIONS ──────────────────────────────
          _Section(
            icon: Icons.tune,
            titre: 'Opérations',
            couleur: const Color(0xFF3B82F6),
            children: [
              _Tuile(
                icon: Icons.lock_outline,
                label: 'Changer le PIN',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PinScreen(
                              titre: 'Nouveau PIN',
                              sousTitre: 'Définir un nouveau code PIN',
                              modeDefinition: true,
                              onSuccess: (_) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text('PIN mis à jour !'),
                                        backgroundColor: kVert,
                                        behavior: SnackBarBehavior.floating));
                              },
                            ))),
              ),
              _divider(context),
              StatefulBuilder(builder: (ctx, setN) => _TuileSub(
                icon: Icons.phone_android,
                label: 'Numéros Tmoney / Flooz',
                sub: NumerosManager.tmoney.isNotEmpty || NumerosManager.flooz.isNotEmpty
                    ? '${NumerosManager.tmoney.isNotEmpty ? "T: +228 ${NumerosManager.tmoney}" : ""}${NumerosManager.tmoney.isNotEmpty && NumerosManager.flooz.isNotEmpty ? " · " : ""}${NumerosManager.flooz.isNotEmpty ? "F: +228 ${NumerosManager.flooz}" : ""}'
                    : 'Non définis',
                onTap: () => _gestionNumeros(setN),
              )),
            ],
          ),
          const SizedBox(height: 8),

          // ─── PRÉFÉRENCES ─────────────────────────────
          _Section(
            icon: Icons.settings_outlined,
            titre: 'Préférences',
            couleur: kVert,
            children: [
              StatefulBuilder(builder: (ctx, setS) => _Toggle(
                icon: Icons.euro_outlined,
                label: 'Conversion EUR',
                value: NumerosManager.conversionEurOn,
                onChanged: (v) async {
                  await NumerosManager.setConversionEur(v);
                  setS(() {});
                },
              )),
              _divider(context),
              StatefulBuilder(builder: (ctx, setS) => _Toggle(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                value: NumerosManager.notificationsOn,
                onChanged: (v) async {
                  await NumerosManager.setNotifications(v);
                  setS(() {});
                },
              )),
              _divider(context),
              StatefulBuilder(builder: (ctx, setS) => _Toggle(
                icon: ThemeManager.instance.isDark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                label: 'Mode sombre',
                value: ThemeManager.instance.isDark,
                onChanged: (_) {
                  ThemeManager.instance.toggle();
                  setS(() {});
                },
              )),
            ],
          ),
          const SizedBox(height: 8),

          // ─── À PROPOS ─────────────────────────────────
          _Section(
            icon: Icons.info_outline,
            titre: 'À propos',
            couleur: Colors.grey,
            children: [
              _Tuile(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                onTap: () async {
                  final url = Uri.parse(
                      'https://coursiertogo.github.io/haya-privacy/privacy_policy.html');
                  if (await canLaunchUrl(url)) {
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _divider(context),
              _Tuile(
                icon: Icons.info_outline,
                label: 'Version 1.0.0 · Flexix · Pays-Bas',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Haya',
                  applicationVersion: '1.0.0',
                  applicationLegalese: "Envoie. C'est parti.\n© 2026 Flexix",
                ),
                trailing: false,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── DÉCONNEXION ─────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: kRouge, size: 18),
            label: const Text('Se déconnecter',
                style: TextStyle(color: kRouge, fontSize: 15)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kRouge),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: kCardCtx(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('Déconnexion',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTextCtx(context))),
                content: Text(
                    'Voulez-vous vraiment vous déconnecter ?',
                    style: TextStyle(
                        fontSize: 14, color: kSubtextCtx(context))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler',
                          style: TextStyle(color: Colors.grey))),
                  TextButton(
                    onPressed: () async {
                      await UserManager.effacer();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (r) => false);
                    },
                    child: const Text('Déconnecter',
                        style: TextStyle(
                            color: kRouge, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _gestionNumeros(StateSetter refresh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardCtx(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          final tmoneyValide = _tmoneyCtrl.text.isEmpty ||
              detectOperateur(_tmoneyCtrl.text) == 'tmoney';
          final floozValide = _floozCtrl.text.isEmpty ||
              detectOperateur(_floozCtrl.text) == 'flooz';
          final peutSauvegarder = tmoneyValide &&
              floozValide &&
              (_tmoneyCtrl.text.isNotEmpty || _floozCtrl.text.isNotEmpty);
          return Padding(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mes numéros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: kTextCtx(ctx))),
              const SizedBox(height: 4),
              Text('Utilisés pour les demandes de paiement',
                  style: TextStyle(fontSize: 12, color: kSubtextCtx(ctx))),
              const SizedBox(height: 20),
              _NumChamp(label: 'Numéro Tmoney', hint: '90123456',
                  controller: _tmoneyCtrl, valide: tmoneyValide,
                  msgErreur: "Pas un numéro Tmoney", onChanged: () => setM(() {})),
              const SizedBox(height: 12),
              _NumChamp(label: 'Numéro Flooz', hint: '94123456',
                  controller: _floozCtrl, valide: floozValide,
                  msgErreur: "Pas un numéro Flooz", onChanged: () => setM(() {})),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: peutSauvegarder ? () async {
                    await NumerosManager.setTmoney(_tmoneyCtrl.text);
                    await NumerosManager.setFlooz(_floozCtrl.text);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    refresh(() {});
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Numéros sauvegardés !'),
                        backgroundColor: kVert,
                        behavior: SnackBarBehavior.floating));
                  } : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Sauvegarder',
                      style: TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ─── WIDGETS ─────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String titre;
  final Color couleur;
  final List<Widget> children;
  const _Section({required this.icon, required this.titre,
      required this.couleur, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: kCardCtx(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderCtx(context))),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: couleur, size: 18),
        ),
        title: Text(titre,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: kTextCtx(context))),
        iconColor: kSubtextCtx(context),
        collapsedIconColor: kSubtextCtx(context),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        children: children,
      ),
    ),
  );
}

class _Tuile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool trailing;
  const _Tuile({required this.icon, required this.label,
      required this.onTap, this.trailing = true});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: kSubtextCtx(context)),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
        if (trailing) Icon(Icons.chevron_right, size: 18, color: kSubtextCtx(context)),
      ]),
    ),
  );
}

class _TuileSub extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  const _TuileSub({required this.icon, required this.label,
      required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: kSubtextCtx(context)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, color: kTextCtx(context))),
          Text(sub, style: TextStyle(fontSize: 11, color: kSubtextCtx(context))),
        ])),
        Icon(Icons.chevron_right, size: 18, color: kSubtextCtx(context)),
      ]),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.icon, required this.label,
      required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: kSubtextCtx(context)),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
          style: TextStyle(fontSize: 14, color: kTextCtx(context)))),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: kOrange,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ]),
  );
}

class _NumChamp extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool valide;
  final String msgErreur;
  final VoidCallback onChanged;
  const _NumChamp({required this.label, required this.hint,
      required this.controller, required this.valide,
      required this.msgErreur, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: kSubtextCtx(context))),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
            color: kInputCtx(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: controller.text.isNotEmpty && !valide
                    ? kRouge : Colors.transparent)),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('+228',
                style: TextStyle(fontSize: 14, color: kSubtextCtx(context))),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              style: TextStyle(fontSize: 15, color: kTextCtx(context)),
              decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  counterText: ''),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                  valide ? Icons.check_circle : Icons.error_outline,
                  color: valide ? kVert : kRouge, size: 18),
            ),
        ]),
      ),
      if (controller.text.isNotEmpty && !valide)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(msgErreur,
              style: const TextStyle(color: kRouge, fontSize: 11)),
        ),
    ],
  );
}

Widget _divider(BuildContext context) => Divider(
    height: 1, color: kBorderCtx(context));
