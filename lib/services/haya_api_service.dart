import 'dart:convert';
import 'package:http/http.dart' as http;

class HayaApiService {
  static const String baseUrl = 'https://haya.flexix.nl/api';
  static int utilisateurId = 1;
  static String token = '';
  static String telephone = '';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  static Future<bool> enregistrerTransaction({
    required String telephone,
    required int montant,
    required String operateur,
    required String reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers,
        body: jsonEncode({
          'expediteur_id': utilisateurId,
          'telephone_destinataire': telephone,
          'montant': montant,
          'operateur': operateur,
          'reference': reference,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getHistorique() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$utilisateurId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getHistoriqueRecus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/recues/$telephone'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions']);
      }
      return [];
    } catch (_) {
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
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) token = data['token'];
        return data['utilisateur'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> creerDemande({
    required String telephone,
    required int montant,
    required String objet,
    required String operateur,
    required String reference,
    String? telephonePayeur,
  }) async {
    try {
      final body = <String, dynamic>{
        'expediteur_id': utilisateurId,
        'telephone_destinataire': telephone,
        'montant': montant,
        'objet': objet,
        'operateur': operateur,
        'reference': reference,
      };
      if (telephonePayeur != null && telephonePayeur.isNotEmpty) {
        body['telephone_payeur'] = telephonePayeur;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/demandes'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getDemandes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/$utilisateurId'),
        headers: _headers,
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

  static Future<List<Map<String, dynamic>>> getDemandesEnvoyees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/$utilisateurId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['demandes']);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getDemandesRecues(String telephone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/recues/$telephone'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['demandes']);
      }
    } catch (_) {}
    return [];
  }

  static Future<void> enregistrerPayeur(String reference) async {
    if (token.isEmpty || reference.isEmpty) return;
    try {
      await http.put(
        Uri.parse('$baseUrl/demandes/apayer/$reference'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getDemandesAPayer(String telephone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/apayer/$telephone'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['demandes']);
      }
    } catch (_) {}
    return [];
  }

  static Future<String> getStatutDemande(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demandes/statut/$reference'),
        headers: _headers,
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
    if (token.isEmpty || reference.isEmpty) return false;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/demandes/payer/$reference'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return true;
      // Retry une fois si échec
      await Future.delayed(const Duration(seconds: 2));
      final retry = await http.put(
        Uri.parse('$baseUrl/demandes/payer/$reference'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return retry.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sauvegarderNumeros({required String tmoney, required String flooz}) async {
    if (token.isEmpty) return false;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/numeros'),
        headers: _headers,
        body: jsonEncode({'num_tmoney': tmoney, 'num_flooz': flooz}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, String>?> recupererNumeros() async {
    if (token.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/numeros'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'tmoney': data['num_tmoney'] ?? '',
          'flooz': data['num_flooz'] ?? '',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/stats/$utilisateurId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
