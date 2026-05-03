import 'package:shared_preferences/shared_preferences.dart';
import 'haya_api_service.dart';

// ─── NUMÉROS MANAGER ─────────────────────────────────────
class NumerosManager {
  static String _tmoney = '';
  static String _flooz = '';
  static bool _notificationsOn = true;
  static bool _conversionEurOn = false;

  static String get tmoney => _tmoney;
  static String get flooz => _flooz;
  static bool get notificationsOn => _notificationsOn;
  static bool get conversionEurOn => _conversionEurOn;

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _tmoney = prefs.getString('num_tmoney') ?? '';
    _flooz = prefs.getString('num_flooz') ?? '';
    _notificationsOn = prefs.getBool('notifications_on') ?? true;
    _conversionEurOn = prefs.getBool('conversion_eur_on') ?? false;
  }

  static Future<void> setTmoney(String v) async {
    _tmoney = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('num_tmoney', v);
  }

  static Future<void> setFlooz(String v) async {
    _flooz = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('num_flooz', v);
  }

  static Future<void> setNotifications(bool v) async {
    _notificationsOn = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_on', v);
  }

  static Future<void> setConversionEur(bool v) async {
    _conversionEurOn = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('conversion_eur_on', v);
  }
}

// ─── PIN MANAGER ─────────────────────────────────────────
class PinManager {
  static String _pin = '123456';
  static bool _pinDefini = false;
  static int _tentativesEchouees = 0;
  static DateTime? _blocageJusqua;

  static bool get pinDefini => _pinDefini;

  static bool get estBloque {
    if (_blocageJusqua == null) return false;
    if (DateTime.now().isAfter(_blocageJusqua!)) {
      _blocageJusqua = null;
      _tentativesEchouees = 0;
      return false;
    }
    return true;
  }

  static Duration get tempsBlocage {
    if (_blocageJusqua == null) return Duration.zero;
    final r = _blocageJusqua!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  static int get tentativesRestantes =>
      (5 - _tentativesEchouees).clamp(0, 5);

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _pinDefini = prefs.getBool('pin_defini') ?? false;
    _pin = prefs.getString('pin') ?? '123456';
  }

  static Future<void> definirPin(String pin) async {
    _pin = pin;
    _pinDefini = true;
    _tentativesEchouees = 0;
    _blocageJusqua = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', pin);
    await prefs.setBool('pin_defini', true);
  }

  static bool verifierPin(String pin) {
    if (estBloque) return false;
    if (pin == _pin) {
      _tentativesEchouees = 0;
      return true;
    }
    _tentativesEchouees++;
    if (_tentativesEchouees >= 5) {
      _blocageJusqua = DateTime.now().add(const Duration(seconds: 30));
    }
    return false;
  }
}

// ─── USER MANAGER ────────────────────────────────────────
class UserManager {
  static String nom = '';
  static String prenom = '';
  static String email = '';
  static String telephone = '';
  static int id = 0;
  static String token = '';

  static String get nomComplet => '$prenom $nom'.trim();
  static String get initiales {
    final n = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final p = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$n$p';
  }

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    nom = prefs.getString('user_nom') ?? '';
    prenom = prefs.getString('user_prenom') ?? '';
    email = prefs.getString('user_email') ?? '';
    telephone = prefs.getString('user_telephone') ?? '';
    id = prefs.getInt('user_id') ?? 0;
    token = prefs.getString('user_token') ?? '';
    HayaApiService.utilisateurId = id;
    HayaApiService.token = token;
  }

  static Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nom', nom);
    await prefs.setString('user_prenom', prenom);
    await prefs.setString('user_email', email);
    await prefs.setString('user_telephone', telephone);
    await prefs.setInt('user_id', id);
    await prefs.setString('user_token', token);
  }

  static Future<void> effacer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_nom');
    await prefs.remove('user_prenom');
    await prefs.remove('user_email');
    await prefs.remove('user_telephone');
    await prefs.remove('user_id');
    await prefs.remove('user_token');
    token = '';
    HayaApiService.token = '';
  }
}

// ─── CONTACT ─────────────────────────────────────────────
class Contact {
  final String nom, numero, operateur;
  final int colorIndex;
  Contact({
    required this.nom,
    required this.numero,
    required this.operateur,
    required this.colorIndex,
  });
}

class ContactsManager {
  static final List<Contact> contacts = [];

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('contacts') ?? [];
    contacts.clear();
    for (final s in data) {
      final parts = s.split('|');
      if (parts.length == 4) {
        contacts.add(Contact(
          nom: parts[0],
          numero: parts[1],
          operateur: parts[2],
          colorIndex: int.tryParse(parts[3]) ?? 0,
        ));
      }
    }
  }

  static Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'contacts',
      contacts.map((c) => '${c.nom}|${c.numero}|${c.operateur}|${c.colorIndex}').toList(),
    );
  }
}
