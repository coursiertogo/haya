import 'package:flutter/material.dart';
import '../constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondCtx(context),
      appBar: AppBar(
        backgroundColor: kNuit,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Politique de confidentialité',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(context),
          const SizedBox(height: 20),
          _section(context, 'Éditeur', Icons.business_outlined, kOrange, [
            'Application : Haya',
            'Éditeur : Flexix — Heerenveen, Pays-Bas',
            'Contact : info@flexix.nl',
            'Dernière mise à jour : Mai 2026',
          ]),
          _section(context, 'Données collectées', Icons.data_usage_outlined, const Color(0xFF6366F1), [
            'Numéro de téléphone (authentification et identification)',
            'Nom et prénom (affichage dans l\'application)',
            'Numéros Tmoney / Flooz enregistrés',
            'Historique des transactions effectuées via Haya',
            'Demandes de paiement créées et reçues',
          ]),
          _section(context, 'Utilisation des données', Icons.shield_outlined, const Color(0xFF10B981), [
            'Authentification sécurisée par code SMS (OTP)',
            'Exécution des transferts d\'argent mobile',
            'Affichage de l\'historique et des statistiques',
            'Envoi de notifications de paiement',
            'Aucune vente ni partage de vos données à des tiers à des fins commerciales',
          ]),
          _section(context, 'Services tiers', Icons.handshake_outlined, const Color(0xFFF59E0B), [
            'Twilio — Envoi des SMS de vérification OTP. Politique : twilio.com/legal/privacy',
            'FeexPay — Traitement des paiements mobile money (Tmoney / Flooz). Politique : feexpay.me',
          ]),
          _section(context, 'Sécurité', Icons.lock_outline, const Color(0xFF3B82F6), [
            'Authentification par jeton JWT (expiration : 30 jours)',
            'Code PIN local chiffré sur l\'appareil',
            'Verrouillage automatique après 5 minutes d\'inactivité',
            'Communications sécurisées via HTTPS (TLS)',
            'Limitation des tentatives OTP : 3 envois / 10 min, 5 essais avant blocage',
          ]),
          _section(context, 'Conservation des données', Icons.history_outlined, Colors.grey, [
            'Vos données sont conservées tant que votre compte est actif.',
            'En cas de suppression de compte, vos données personnelles sont effacées dans un délai de 30 jours.',
            'L\'historique des transactions est conservé à des fins de traçabilité légale.',
          ]),
          _section(context, 'Vos droits', Icons.verified_user_outlined, kOrange, [
            'Accès : consulter vos données personnelles depuis l\'application',
            'Rectification : modifier votre nom depuis les Paramètres',
            'Suppression : contacter info@flexix.nl pour demander la suppression de votre compte',
            'Portabilité : demander une copie de vos données par email',
          ]),
          _section(context, 'Contact', Icons.email_outlined, const Color(0xFF6366F1), [
            'Pour toute question relative à vos données personnelles :',
            'info@flexix.nl',
          ]),
          const SizedBox(height: 12),
          Center(
            child: Text('© 2026 Flexix — Tous droits réservés',
                style: TextStyle(fontSize: 12, color: kSubtextCtx(context))),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF080818), Color(0xFF141430)]),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: kOrange, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.privacy_tip_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('Haya',
              style: TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        const Text('Politique de confidentialité',
            style: TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text(
            'Haya respecte votre vie privée. Ce document explique quelles données nous collectons, pourquoi, et comment nous les protégeons.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _section(BuildContext context, String titre, IconData icon,
      Color couleur, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: kCardCtx(context),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: couleur, size: 16),
            ),
            const SizedBox(width: 10),
            Text(titre,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: kTextCtx(context))),
          ]),
          const SizedBox(height: 12),
          ...points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 5, height: 5,
                decoration: BoxDecoration(
                    color: couleur, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p,
                    style: TextStyle(
                        fontSize: 13, color: kSubtextCtx(context),
                        height: 1.5)),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}
