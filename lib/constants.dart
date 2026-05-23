import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── FEATURE FLAGS ───────────────────────────────────────
// Mettre à true quand cross-opérateur FeexPay est résolu
const bool kEnvoiActif = false;
const bool kScannerActif = false;
const bool kRecevoirActif = false;

// ─── THEME MANAGER ───────────────────────────────────────
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;
  ThemeManager._();

  bool _isDark = false;
  bool get isDark => _isDark;

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDark);
    notifyListeners();
  }
}

// ─── COULEURS HAYA ───────────────────────────────────────
const kNuit     = Color(0xFF0D0D2B);
const kOrange   = Color(0xFFF97316);
const kVert     = Color(0xFF1D9E75);
const kRouge    = Color(0xFFE24B4A);

// Thème Haya — fond clair violacé + header bleu
const kBleu      = Color(0xFF5568D9); // header / nav / accents
const kBleuCard  = Color(0xFF6678E5); // cards header
const kBleuDark  = Color(0xFF4457C8); // éléments header sombres
const kBleuDeep  = Color(0xFF3344B8); // nav bar

// Fond principal clair
const kFond      = Color(0xFFF5F4FF); // fond écrans
const kCardLight = Color(0xFFFFFFFF); // cards
const kCardDark  = Color(0xFFEEEDFB); // cards légèrement colorées

// Couleurs mode sombre
const kFondDarkMode  = Color(0xFF0D1226);
const kCardDarkMode  = Color(0xFF1A2040);
const kInputDarkMode = Color(0xFF242B4E);
const kBordDarkMode  = Color(0xFF2E3660);

// Fonctions contextuelles — clair / sombre
Color kFondCtx(BuildContext context)    => Theme.of(context).brightness == Brightness.dark ? kFondDarkMode  : kFond;
Color kCardCtx(BuildContext context)    => Theme.of(context).brightness == Brightness.dark ? kCardDarkMode  : kCardLight;
Color kTextCtx(BuildContext context)    => Theme.of(context).brightness == Brightness.dark ? Colors.white   : const Color(0xFF111827);
Color kSubtextCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9999BB) : const Color(0xFF6B7280);
Color kBorderCtx(BuildContext context)  => Theme.of(context).brightness == Brightness.dark ? kBordDarkMode  : const Color(0xFFE5E7EB);
Color kInputCtx(BuildContext context)   => Theme.of(context).brightness == Brightness.dark ? kInputDarkMode : const Color(0xFFF3F4F6);
const kFondDark = kFond;

const avatarColors = [
  Color(0xFFEEEDFE), Color(0xFFD7F3EA), Color(0xFFFAEEDA),
  Color(0xFFFFE4E4), Color(0xFFE4F0FF), Color(0xFFF0E4FF),
];
const avatarTextColors = [
  Color(0xFF3C3489), Color(0xFF0F6E56), Color(0xFF854F0B),
  Color(0xFFA32D2D), Color(0xFF185FA5), Color(0xFF6B21A8),
];

// ─── OPÉRATEURS ──────────────────────────────────────────
const tmoneySuffixes = ['70', '71', '90', '91', '92', '93'];
const floozPrefixes = ['79', '94', '95', '96', '97', '98', '99'];

String detectOperateur(String numero) {
  final clean = numero.replaceAll(RegExp(r'\D'), '');
  if (clean.length < 2) return '';
  final prefix = clean.substring(0, 2);
  if (tmoneySuffixes.contains(prefix)) return 'tmoney';
  if (floozPrefixes.contains(prefix)) return 'flooz';
  return 'inconnu';
}

// ─── LOGO OPÉRATEUR ──────────────────────────────────────
class OpLogo extends StatelessWidget {
  final String operateur; // 'tmoney' ou 'flooz'
  final double height;
  const OpLogo({super.key, required this.operateur, this.height = 22});

  @override
  Widget build(BuildContext context) {
    final asset = operateur == 'tmoney'
        ? 'assets/logos/tmoney.png'
        : 'assets/logos/moov.png';
    return Image.asset(asset, height: height, fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Text(
            operateur == 'tmoney' ? 'Tmoney' : 'Flooz',
            style: TextStyle(fontSize: height * 0.6, fontWeight: FontWeight.w600)));
  }
}

// ─── PARTAGE ─────────────────────────────────────────────
Future<void> partagerWhatsApp(String message) async {
  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> partagerSMS(String message) async {
  final url = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
}
