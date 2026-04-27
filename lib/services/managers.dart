import 'package:shared_preferences/shared_preferences.dart';
import 'haya_api_service.dart';

// ─── NUMÉROS MANAGER ─────────────────────────────────────
class NumerosManager {
  static String _tmoney = '';
  static String _flooz = '';
  static bool _notificationsOn = true;
  static bool _conversionEurOn = true;

  static String get tmoney => _tmoney;
  static String get flooz => _flooz;
  static bool get notificationsOn => _notificationsOn;
  static bool get conversionEurOn => _conversionEurOn;

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _tmoney = prefs.getString('num_tmoney') ?? '';
    _flooz = prefs.getString('num_flooz') ?? '';
    _notificationsOn = prefs.getBool('notifications_on') ?? true;
    _conversionEurOn = prefs.getBool('conversion_eur_on') ?? true;
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
  static String _pin = '1234';
  static bool _pinDefini = false;
  static bool get pinDefini => _pinDefini;

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _pinDefini = prefs.getBool('pin_defini') ?? false;
    _pin = prefs.getString('pin') ?? '1234';
  }

  static Future<void> definirPin(String pin) async {
    _pin = pin;
    _pinDefini = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', pin);
    await prefs.setBool('pin_defini', true);
  }

  static bool verifierPin(String pin) => pin == _pin;
}

// ─── USER MANAGER ────────────────────────────────────────
class UserManager {
  static String nom = '';
  static String prenom = '';
  static String email = '';
  static String telephone = '';
  static int id = 0;

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
    HayaApiService.utilisateurId = id;
  }

  static Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nom', nom);
    await prefs.setString('user_prenom', prenom);
    await prefs.setString('user_email', email);
    await prefs.setString('user_telephone', telephone);
    await prefs.setInt('user_id', id);
  }

  static Future<void> effacer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_nom');
    await prefs.remove('user_prenom');
    await prefs.remove('user_email');
    await prefs.remove('user_telephone');
    await prefs.remove('user_id');
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
  static final List<Contact> contacts = [
    Contact(nom: 'Ama Kpodo', numero: '90123456', operateur: 'tmoney', colorIndex: 0),
    Contact(nom: 'Yawa Bossa', numero: '94567890', operateur: 'flooz', colorIndex: 1),
    Contact(nom: 'Kofi Dossou', numero: '91234567', operateur: 'tmoney', colorIndex: 4),
    Contact(nom: 'Edem Klu', numero: '97654321', operateur: 'flooz', colorIndex: 5),
  ];
}
