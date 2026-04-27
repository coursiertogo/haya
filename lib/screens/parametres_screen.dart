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
  bool _notifications = true;
  final _tmoneyCtrl = TextEditingController();
  final _floozCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tmoneyCtrl.text = NumerosManager.tmoney;
    _floozCtrl.text = NumerosManager.flooz;
    _notifications = NumerosManager.notificationsOn;
  }

  @override
  void dispose() {
    _tmoneyCtrl.dispose();
    _floozCtrl.dispose();
    super.dispose();
  }

  Widget _sectionTitre(String titre) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(titre.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kOrange,
                letterSpacing: 1.2)),
      );

  Widget _tuile(
          {required IconData icon,
          required String titre,
          required String sousTitre,
          required VoidCallback onTap}) =>
      ListTile(
        leading: Icon(icon, color: kOrange),
        title: Text(titre,
            style: TextStyle(color: kTextCtx(context))),
        subtitle: Text(sousTitre,
            style: TextStyle(color: kSubtextCtx(context))),
        trailing: Icon(Icons.chevron_right, color: kSubtextCtx(context)),
        onTap: onTap,
      );

  void _afficherGestionNumeros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardCtx(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          final opTmoney = detectOperateur(_tmoneyCtrl.text);
          final opFlooz = detectOperateur(_floozCtrl.text);
          final tmoneyValide =
              _tmoneyCtrl.text.isEmpty || opTmoney == 'tmoney';
          final floozValide =
              _floozCtrl.text.isEmpty || opFlooz == 'flooz';
          final peutSauvegarder = tmoneyValide &&
              floozValide &&
              (_tmoneyCtrl.text.isNotEmpty || _floozCtrl.text.isNotEmpty);
          return Padding(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes numeros',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextCtx(ctx))),
                  const SizedBox(height: 6),
                  Text(
                      'Ces numeros seront utilises dans Demande de paiement',
                      style: TextStyle(
                          fontSize: 12, color: kSubtextCtx(ctx))),
                  const SizedBox(height: 20),
                  Text('Numero Tmoney',
                      style: TextStyle(
                          fontSize: 13, color: kSubtextCtx(ctx))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: kInputCtx(ctx),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _tmoneyCtrl.text.isNotEmpty &&
                                    !tmoneyValide
                                ? kRouge
                                : Colors.transparent)),
                    child: Row(children: [
                      Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('+228',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: kSubtextCtx(ctx)))),
                      Expanded(
                        child: TextField(
                          controller: _tmoneyCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 8,
                          style: TextStyle(
                              fontSize: 15, color: kTextCtx(ctx)),
                          decoration: const InputDecoration(
                              hintText: 'Ex: 90123456',
                              border: InputBorder.none,
                              counterText: ''),
                          onChanged: (_) => setM(() {}),
                        ),
                      ),
                    ]),
                  ),
                  if (_tmoneyCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: tmoneyValide
                          ? const Row(children: [
                              Icon(Icons.check_circle,
                                  color: kVert, size: 14),
                              SizedBox(width: 4),
                              Text('Tmoney valide',
                                  style: TextStyle(
                                      color: kVert, fontSize: 12)),
                            ])
                          : const Row(children: [
                              Icon(Icons.error_outline,
                                  color: kRouge, size: 14),
                              SizedBox(width: 4),
                              Text("Ce numero n'est pas Tmoney",
                                  style: TextStyle(
                                      color: kRouge, fontSize: 12)),
                            ]),
                    ),
                  const SizedBox(height: 14),
                  Text('Numero Flooz',
                      style: TextStyle(
                          fontSize: 13, color: kSubtextCtx(ctx))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: kInputCtx(ctx),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                _floozCtrl.text.isNotEmpty && !floozValide
                                    ? kRouge
                                    : Colors.transparent)),
                    child: Row(children: [
                      Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('+228',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: kSubtextCtx(ctx)))),
                      Expanded(
                        child: TextField(
                          controller: _floozCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 8,
                          style: TextStyle(
                              fontSize: 15, color: kTextCtx(ctx)),
                          decoration: const InputDecoration(
                              hintText: 'Ex: 94123456',
                              border: InputBorder.none,
                              counterText: ''),
                          onChanged: (_) => setM(() {}),
                        ),
                      ),
                    ]),
                  ),
                  if (_floozCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: floozValide
                          ? const Row(children: [
                              Icon(Icons.check_circle,
                                  color: kVert, size: 14),
                              SizedBox(width: 4),
                              Text('Flooz valide',
                                  style: TextStyle(
                                      color: kVert, fontSize: 12)),
                            ])
                          : const Row(children: [
                              Icon(Icons.error_outline,
                                  color: kRouge, size: 14),
                              SizedBox(width: 4),
                              Text("Ce numero n'est pas Flooz",
                                  style: TextStyle(
                                      color: kRouge, fontSize: 12)),
                            ]),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: peutSauvegarder
                          ? () async {
                              await NumerosManager.setTmoney(
                                  _tmoneyCtrl.text);
                              await NumerosManager.setFlooz(
                                  _floozCtrl.text);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content:
                                    Text('Numeros sauvegardes !'),
                                backgroundColor: kVert,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Sauvegarder',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        foregroundColor: Colors.white,
        title: const Text('Paramètres',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(children: [
        _sectionTitre('Sécurité'),
        _tuile(
          icon: Icons.lock_outline,
          titre: 'Changer le PIN',
          sousTitre: 'Modifier votre code PIN à 4 chiffres',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PinScreen(
                        titre: 'Nouveau PIN',
                        sousTitre: 'Définir un nouveau code PIN',
                        modeDefinition: true,
                        onSuccess: (_) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('PIN mis à jour !'),
                                  backgroundColor: kVert,
                                  behavior:
                                      SnackBarBehavior.floating));
                        },
                      ))),
        ),
        _sectionTitre('Mes numéros'),
        _tuile(
          icon: Icons.phone_android,
          titre: 'Numéros Tmoney / Flooz',
          sousTitre: NumerosManager.tmoney.isNotEmpty ||
                  NumerosManager.flooz.isNotEmpty
              ? 'Tmoney: ${NumerosManager.tmoney.isNotEmpty ? "+228 ${NumerosManager.tmoney}" : "Non défini"} · Flooz: ${NumerosManager.flooz.isNotEmpty ? "+228 ${NumerosManager.flooz}" : "Non défini"}'
              : 'Gérer vos numéros de réception',
          onTap: _afficherGestionNumeros,
        ),
        _sectionTitre('Affichage'),
        StatefulBuilder(builder: (context, setS) {
          return SwitchListTile(
            secondary:
                const Icon(Icons.euro_outlined, color: kOrange),
            title: Text('Conversion EUR',
                style: TextStyle(color: kTextCtx(context))),
            subtitle: Text('Afficher les equivalents en euros',
                style: TextStyle(color: kSubtextCtx(context))),
            value: NumerosManager.conversionEurOn,
            activeThumbColor: kOrange,
            onChanged: (val) async {
              await NumerosManager.setConversionEur(val);
              setS(() {});
            },
          );
        }),
        _sectionTitre('Notifications'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined,
              color: kOrange),
          title: Text('Notifications',
              style: TextStyle(color: kTextCtx(context))),
          subtitle: Text('Recevoir les alertes de transfert',
              style: TextStyle(color: kSubtextCtx(context))),
          value: _notifications,
          activeThumbColor: kOrange,
          onChanged: (val) async {
            setState(() => _notifications = val);
            await NumerosManager.setNotifications(val);
          },
        ),
        _sectionTitre('Apparence'),
        StatefulBuilder(builder: (context, setS) {
          return SwitchListTile(
            secondary: Icon(
                ThemeManager.instance.isDark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: kOrange),
            title: Text('Mode sombre',
                style: TextStyle(color: kTextCtx(context))),
            subtitle: Text("Changer l'apparence de l'app",
                style: TextStyle(color: kSubtextCtx(context))),
            value: ThemeManager.instance.isDark,
            activeThumbColor: kOrange,
            onChanged: (val) {
              ThemeManager.instance.toggle();
              setS(() {});
            },
          );
        }),
        _sectionTitre('À propos'),
        _tuile(
          icon: Icons.privacy_tip_outlined,
          titre: 'Politique de confidentialité',
          sousTitre: 'Voir notre politique',
          onTap: () async {
            final url = Uri.parse(
                'https://coursiertogo.github.io/haya-privacy/privacy_policy.html');
            if (await canLaunchUrl(url)) {
              launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _tuile(
          icon: Icons.info_outline,
          titre: 'À propos de Haya',
          sousTitre: 'Version 1.0.0 · Flexix · Pays-Bas',
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Haya',
            applicationVersion: '1.0.0',
            applicationLegalese: "Envoie. C'est parti.\n© 2026 Flexix · Heerenveen",
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: kRouge),
            label: const Text('Déconnexion',
                style: TextStyle(color: kRouge, fontSize: 15)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kRouge),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                (r) => false),
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }
}
