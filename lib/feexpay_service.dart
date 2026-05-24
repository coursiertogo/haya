import 'dart:convert';
import 'package:http/http.dart' as http;

class FeexPayService {
  // ─── CONFIGURATION ───────────────────────────────────
  // ⚠️ Remplace par ta vraie clé API sandbox depuis le menu Développeurs
  static const String _apiKey = 'fp_xJCr90csVp0ZjDOaslH2biMRuey7d0MbZDY2D6SmXKJM3tabayLKwLXseTfxaaws';
  static const String _shopId = 'yl8mn0u9Lc0R7p6';

  // URLs API FeexPay
  static const String _urlTogocom =
      'https://api-v2.feexpay.me/api/transactions/public/requesttopay/togocom_tg';
  static const String _urlMoov =
      'https://api-v2.feexpay.me/api/transactions/public/requesttopay/moov_tg';

  // MODE PRODUCTION
  static const bool _modeSandbox = false;
  static bool get modeSandbox => _modeSandbox;

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

      print('FEEXPAY STATUS: ${response.statusCode}');
      print('FEEXPAY BODY: ${response.body}');
      final data = jsonDecode(response.body);

      // FeexPay retourne 200, 201 ou 202 quand l'USSD est envoyé
      // Tout code < 400 = transaction initiée (USSD envoyé au téléphone)
      if (response.statusCode < 400) {
        // FeexPay peut nommer l'ID différemment selon la version
        final txId = (data['id'] ?? data['transactionId'] ??
            data['transaction_id'] ?? data['uid'] ?? data['_id'] ??
            data['reference'] ?? '')
            .toString();
        return {
          'success': true,
          'reference': data['reference'] ?? reference,
          'transactionId': txId,
          'rawResponse': data.toString(),
          'message': 'Confirme sur ton téléphone via le code USSD',
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

  // ─── PAYOUT via backend VPS (IP whitelisted) ─────────
  static Future<Map<String, dynamic>> payerDestinataire({
    required String telephone,
    required int montant,
    required String reseau,
    required String reference,
  }) async {
    if (_modeSandbox) return {'success': true};
    try {
      final response = await http.post(
        Uri.parse('https://haya.flexix.nl/api/payout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': telephone,
          'montant': montant,
          'operateur': reseau,
          'reference': reference,
        }),
      ).timeout(const Duration(seconds: 35));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      final data = jsonDecode(response.body);
      final msg = data['message']?.toString() ?? '';
      return {
        'success': false,
        'message': msg.toLowerCase().contains('subscriber') ||
                msg.toLowerCase().contains('invalid') ||
                msg.toLowerCase().contains('not found')
            ? 'Le numéro destinataire n\'est pas enregistré sur ${reseau == 'tmoney' ? 'Tmoney' : 'Flooz'}.'
            : msg.isEmpty ? 'Échec de l\'envoi au destinataire.' : msg,
      };
    } catch (_) {
      return {'success': false, 'message': 'Erreur de connexion lors de l\'envoi.'};
    }
  }

  // ─── VÉRIFIER STATUT TRANSACTION ─────────────────────
  // Utilise le backend comme oracle (webhook → Map en mémoire)
  // L'API FeexPay directe retourne 404 en production
  static Future<String> verifierStatut(String transactionId) async {
    if (_modeSandbox) return 'SUCCESSFUL';
    if (transactionId.isEmpty) return 'PENDING';
    try {
      final response = await http.get(
        Uri.parse('https://haya.flexix.nl/api/tx-check/$transactionId'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statut = (data['statut'] ?? '').toString();
        if (statut == 'succes') return 'SUCCESSFUL';
        if (statut == 'echec') return 'FAILED';
        if (statut == 'payout_echec') return 'PAYOUT_FAILED';
        return 'PENDING';
      }
    } catch (_) {}
    return 'PENDING';
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

  // ─── CALCUL DES FRAIS HAYA (3%) ──────────────────────
  static int calculerFrais(int montant) {
    if (montant < 1000) return 0; // Montant minimum 1000 FCFA
    final frais = (montant * 0.03).round();
    return frais < 30 ? 30 : frais; // Minimum 30 FCFA
  }

  static int montantTotal(int montant) => montant + calculerFrais(montant);
}
