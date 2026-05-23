import 'package:flutter/material.dart';
import 'managers.dart';
import 'haya_api_service.dart';
import '../screens/lock_screen.dart';
import '../screens/main_screen.dart';
import '../screens/onboarding_screen.dart';

/// Déconnecte l'utilisateur et redirige :
/// - Même appareil (PIN défini) → LockScreen (reconnnexion par PIN)
/// - Nouvel appareil / pas de PIN → OnboardingScreen
Future<void> seDeconnecter(BuildContext ctx) async {
  await UserManager.effacer();
  if (!ctx.mounted) return;

  if (PinManager.pinDefini && UserManager.telephone.isNotEmpty) {
    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          onDeverrouille: () {},
          naviguerApres: reconnecterEtOuvrir,
        ),
      ),
      (r) => false,
    );
  } else {
    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (r) => false,
    );
  }
}

/// Applique les numéros Tmoney/Flooz depuis un objet utilisateur (réponse backend).
/// N'écrase les numéros locaux que s'ils sont absents.
Future<void> appliquerNumeros(Map<String, dynamic> utilisateur) async {
  if (NumerosManager.tmoney.isEmpty && NumerosManager.flooz.isEmpty) {
    final t = utilisateur['num_tmoney'];
    final f = utilisateur['num_flooz'];
    if (t != null && t.toString().isNotEmpty) await NumerosManager.setTmoney(t.toString());
    if (f != null && f.toString().isNotEmpty) await NumerosManager.setFlooz(f.toString());
  }
}

/// Renouvelle le token via le backend puis ouvre MainScreen.
Future<void> reconnecterEtOuvrir(BuildContext ctx) async {
  final result = await HayaApiService.inscrireUtilisateur(
    prenom: UserManager.prenom.isNotEmpty ? UserManager.prenom : 'Utilisateur',
    telephone: UserManager.telephone,
  );
  if (result != null) {
    UserManager.id = result['id'] ?? UserManager.id;
    UserManager.prenom = result['prenom'] ?? UserManager.prenom;
    UserManager.nom = result['nom'] ?? UserManager.nom;
    HayaApiService.utilisateurId = UserManager.id;
    UserManager.token = HayaApiService.token;
    await UserManager.sauvegarder();
    await appliquerNumeros(result);
  }
  if (ctx.mounted) {
    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (r) => false,
    );
  }
}
