import 'dart:convert';
import 'package:http/http.dart' as http;

class FeexPayService {
  // ─── CONFIGURATION ───────────────────────────────────
  // ⚠️ Remplace par ta vraie clé API sandbox depuis le menu Développeurs
  static const String _apiKey = 'test_Hg7Kjl3ZAM63UuIUpuudD9nKuu3ZAM67Kjl3Uuhn';
  static const String _shopId = 'yl8mn0u9Lc0R7p6';

  // URLs API FeexPay
  static const String _urlTogocom =
      'https://api-v2.feexpay.me/api/transactions/public/requesttopay/togocom_tg';
  static const String _urlMoov =
      'https://api-v2.feexpay.me/api/transactions/public/requesttopay/moov_tg';

  // ⚠️ MODE SANDBOX — mettre à false quand compte validé en production
  static const bool _modeSandbox = true;

  // ─── INITIER UN PAIEMENT ─────────────────────────────
  static Future<Map<String, dynamic>> initierPaiement({
    required String telephone,
    required int montant,
    required String reseau, // 'tmoney' ou 'flooz'
    required String reference,
    String prenom = 'Client',
    String nom = 'Haya',
  }) async {
    // Mode sandbox — simule un succès
    if (_modeSandbox) {
      await Future.delayed(const Duration(seconds: 2));
      return {
        'success': true,
        'reference': reference,
        'message': 'Paiement simule (mode sandbox FeexPay)',
      };
    }

    try {
      // Choisir l'URL selon l'opérateur
      final url = reseau == 'tmoney' ? _urlTogocom : _urlMoov;

      // Numéro avec indicatif Togo
      final numeroComplet = telephone.startsWith('228')
          ? telephone
          : '228$telephone';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'phoneNumber': numeroComplet,
              'amount': montant,
              'shop': _shopId,
              'first_name': prenom,
              'last_name': nom,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'reference': data['reference'] ?? reference,
          'transactionId': data['id'] ?? '',
          'message': 'Paiement initié avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du paiement. Reessayez.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre internet.',
      };
    }
  }

  // ─── CONVERTIR OPÉRATEUR ─────────────────────────────
  static String convertirOperateur(String operateur) {
    if (operateur == 'tmoney') return 'tmoney';
    if (operateur == 'flooz') return 'flooz';
    return '';
  }

  // ─── GÉNÉRER UNE RÉFÉRENCE UNIQUE ────────────────────
  static String genererReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'HAYA_$timestamp';
  }

  // ─── CALCUL DES FRAIS HAYA (1%) ──────────────────────
  static int calculerFrais(int montant) {
    if (montant < 1000) return 0; // Montant minimum 1000 FCFA
    final frais = (montant * 0.01).round();
    return frais < 10 ? 10 : frais; // Minimum 10 FCFA
  }

  static int montantTotal(int montant) => montant + calculerFrais(montant);
}
