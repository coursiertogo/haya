import 'dart:convert';
import 'package:http/http.dart' as http;

class PayGateService {
  static const String _baseUrl = 'https://paygateglobal.com/api/v2';
  static const String _token = '0dcfd34f-7066-4224-a726-0a73a75e826c';

  // Initier un paiement
  static Future<Map<String, dynamic>> initierPaiement({
    required String telephone,
    required int montant,
    required String reseau, // 'flooz' ou 'tmoney'
    required String reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'phone': telephone,
          'amount': montant,
          'network': reseau,
          'identifier': reference,
          'description': 'Transfert Haya',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reference': data['tx_reference'] ?? reference,
          'message': 'Paiement initié avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du paiement',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion : $e'};
    }
  }

  // Vérifier le statut d'un paiement
  static Future<Map<String, dynamic>> verifierStatut({
    required String reference,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/transaction/status?identifier=$reference&token=$_token',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statut': data['status'],
          'message': data['message'] ?? 'Statut récupéré',
        };
      } else {
        return {'success': false, 'message': 'Erreur lors de la vérification'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur : $e'};
    }
  }

  // Générer une référence unique
  static String genererReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'HAYA_$timestamp';
  }

  // Convertir l'opérateur détecté vers le format PayGate
  static String convertirOperateur(String operateur) {
    if (operateur == 'tmoney') return 'tmoney';
    if (operateur == 'flooz') return 'flooz';
    return '';
  }
}
