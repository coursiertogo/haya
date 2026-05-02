import 'dart:convert';
import 'package:http/http.dart' as http;

class HayaApiService {
  static const String baseUrl = 'https://haya.flexix.nl/api';

  static int utilisateurId = 1;

  static Future<bool> enregistrerTransaction({
    required String telephone,
    required int montant,
    required String operateur,
    required String reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'expediteur_id': utilisateurId,
          'telephone_destinataire': telephone,
          'montant': montant,
          'operateur': operateur,
          'reference': reference,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 201;
    } catch (e) {
      print('Backend non disponible: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getHistorique() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$utilisateurId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions']);
      }
      return [];
    } catch (e) {
      print('Erreur historique: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> inscrireUtilisateur({
    required String prenom,
    required String telephone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/inscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prenom': prenom, 'nom': '', 'telephone': telephone}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['utilisateur'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getDemandes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/$utilisateurId'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['demandes']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<String> getStatutDemande(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/statut/$reference'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statut'] ?? 'inconnu';
      }
      return 'inconnu';
    } catch (_) {
      return 'inconnu';
    }
  }

  static Future<bool> marquerDemandePaye(String reference) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/demandes/payer/$reference'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/stats/$utilisateurId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      }
      return {};
    } catch (e) {
      print('Erreur stats: $e');
      return {};
    }
  }
}
