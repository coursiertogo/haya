import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── THEME MANAGER ───────────────────────────────────────
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;
  ThemeManager._();

  bool _isDark = true;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// ─── COULEURS ────────────────────────────────────────────
const kNuit = Color(0xFF0D0D2B);
const kOrange = Color(0xFFF97316);
const kVert = Color(0xFF1D9E75);
const kFond = Color(0xFFF5F4FF);
const kFondDark = Color(0xFF0D0D2B);
const kRouge = Color(0xFFE24B4A);
const kCardDark = Color(0xFF1A1A3E);

Color kFondCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? kFondDark : kFond;
Color kCardCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? kCardDark : Colors.white;
Color kTextCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
Color kSubtextCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey;
Color kBorderCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200;
Color kInputCtx(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

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

// ─── PARTAGE ─────────────────────────────────────────────
Future<void> partagerWhatsApp(String message) async {
  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> partagerSMS(String message) async {
  final url = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
}
