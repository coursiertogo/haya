import 'dart:convert';
import 'package:http/http.dart' as http;

class TauxChangeService {
  static double _tauxEuroFcfa = 655.957;
  static bool _charge = false;
  static double get tauxEuroFcfa => _tauxEuroFcfa;

  static Future<void> chargerTaux() async {
    if (_charge) return;
    try {
      final r = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/EUR'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final taux = json.decode(r.body)['rates']['XOF'];
        if (taux != null) {
          _tauxEuroFcfa = (taux as num).toDouble();
          _charge = true;
        }
      }
    } catch (_) {}
  }

  static String fcfaVersEuros(int fcfa) =>
      (fcfa / _tauxEuroFcfa).toStringAsFixed(2);
}
