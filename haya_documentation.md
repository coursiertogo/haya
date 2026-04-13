# 📱 HAYA — Documentation Complète du Projet

> App mobile de transfert d'argent vers Tmoney et Flooz au Togo
> Développée avec Flutter | Intégration PayGate Global

---

## 🎯 CONCEPT

- **Nom** : Haya (expression burkinabè = "allez, c'est parti")
- **Slogan** : "Envoie. C'est parti."
- **Couleurs** : Bleu nuit `#0D0D2B` + Orange `#F97316`
- **Cible** : Diaspora togolaise aux Pays-Bas + utilisateurs locaux au Togo
- **Modèle** : Pont de paiement — l'utilisateur paie, Haya route vers PayGate qui livre sur Tmoney/Flooz

---

## 📁 STRUCTURE DU PROJET

```
C:\Users\flexix\Desktop\haya\
├── lib\
│   ├── main.dart              ← Code principal (tous les écrans)
│   ├── main_backup.dart       ← Sauvegarde du code
│   └── paygate_service.dart   ← Service d'intégration PayGate
├── assets\
│   ├── icon.png               ← Icône officielle de l'app
│   ├── haya_icon.png          ← Icône originale
│   └── haya_banner.png        ← Bannière Play Store 1024x500
├── android\                   ← Config Android
├── ios\                       ← Config iOS
├── pubspec.yaml               ← Dépendances Flutter
└── privacy_policy.html        ← Politique de confidentialité
```

---

## 🔧 ENVIRONNEMENT DE DÉVELOPPEMENT

| Outil | Version | Emplacement |
|-------|---------|-------------|
| Flutter | 3.41.6 | `C:\flutter\bin` |
| Android Studio | Panda 3 / 2025.3.3 | Installé |
| VS Code | Dernière version | Installé |
| Git | Configuré | Git Bash |
| Dart | Inclus Flutter | - |

### Commandes essentielles
```bash
flutter run                      # Lancer l'app (choisir 2 pour Chrome)
flutter run -d DEVICE_ID         # Lancer sur téléphone Android
flutter build apk --release      # Générer l'APK final
dart run flutter_launcher_icons  # Générer les icônes
git add .                        # Préparer sauvegarde
git commit -m "message"          # Sauvegarder
```

---

## 📱 ÉCRANS DE L'APP

### 1. MainScreen (Navigation principale)
- BottomNavigationBar avec 4 onglets fonctionnels
- Gère la navigation entre tous les écrans

### 2. HomeScreen (Accueil)
- Header avec dégradé bleu nuit `#0D0D2B → #1e1e6e`
- "Bonjour, Koffi 👋" + solde "125 000 FCFA" (fictif pour l'instant)
- Bouton œil pour cacher/afficher le solde
- Barre d'actions compacte avec icônes orange
- Avatars colorés par personne (6 couleurs)
- "Voir tout" orange → HistoryScreen
- Transactions récentes

### 3. SendScreen (Envoyer)
- Détection automatique Tmoney/Flooz selon préfixe
- Champ numéro avec indicatif 🇹🇬 +228
- Montants rapides : 1000, 2000, 5000, 10000, 25000 FCFA
- Calcul frais PayGate (2.5%)
- Bouton "Envoyer via Tmoney/Flooz"
- Intégration PayGate (mode démo activé)

### 4. ReceiveScreen (Recevoir) ✅ PHASE 2
- Toggle Tmoney / Flooz
- QR Code dessiné en Flutter (sans package externe)
- Numéro affiché clairement avec nom utilisateur
- Bouton "Copier le numéro" → presse-papiers
- Bouton "Partager via WhatsApp/SMS" → message prêt à coller

### 5. HistoryScreen (Activité)
- Filtres : Tout / Tmoney / Flooz / Envois / Reçus
- Stats : Total envoyé + Total reçu
- Liste complète des transactions

### 6. ProfileScreen (Profil)
- Header dégradé avec avatar KA orange
- Stats : Transferts / Total envoyé / Contacts
- Informations personnelles
- Paramètres
- Bouton déconnexion

### 7. SuccessScreen (Confirmation)
- Icône verte de succès
- Récapitulatif du transfert
- Référence #TG-XXXXX
- Statut "Complété ✓"

### 8. LoginScreen (Connexion)
- Toggle Connexion / Inscription
- Champ téléphone avec +228
- Champ mot de passe

---

## 🔑 PRÉFIXES OPÉRATEURS TOGO

```dart
const tmoneySuffixes = ['70', '71', '90', '91', '92', '93'];
const floozPrefixes = ['79', '94', '95', '96', '97', '98', '99'];
```

> ⚠️ Portabilité active depuis mai 2024 — préfixes non garantis à 100%

---

## 💳 INTÉGRATION PAYGATE

### Fichier : `lib/paygate_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PayGateService {
  static const String _baseUrl = 'https://paygateglobal.com/api/v2';
  static const String _token = '0dcfd34f-7066-4224-a726-0a73a75e826c';

  // ⚠️ MODE DÉMO — mettre à false quand PayGate est activé en Production
  static const bool _modeDemo = true;

  static Future<Map<String, dynamic>> initierPaiement({
    required String telephone,
    required int montant,
    required String reseau,
    required String reference,
  }) async {
    if (_modeDemo) {
      await Future.delayed(const Duration(seconds: 2));
      return {'success': true, 'reference': reference, 'message': 'Mode démo'};
    }
    // ... appel PayGate réel
  }
}
```

### Frais PayGate
- Flooz : 2.5%
- Tmoney : 3%

### ⚠️ Activation Production
- Envoyer KVK + CNI à PayGate
- Changer `_modeDemo = true` → `_modeDemo = false`

---

## 🎨 COULEURS ET DESIGN

```dart
const kNuit   = Color(0xFF0D0D2B);  // Bleu nuit principal
const kOrange = Color(0xFFF97316);  // Orange haya
const kVert   = Color(0xFF1D9E75);  // Vert (montants reçus)
const kFond   = Color(0xFFF5F4FF);  // Fond gris-violet clair
const kRouge  = Color(0xFFE24B4A);  // Rouge (montants envoyés)

// Couleurs avatars (6 couleurs distinctes)
const avatarColors = [
  Color(0xFFEEEDFE), Color(0xFFD7F3EA), Color(0xFFFAEEDA),
  Color(0xFFFFE4E4), Color(0xFFE4F0FF), Color(0xFFF0E4FF),
];
```

---

## 📦 DÉPENDANCES (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#0D0D2B"
  adaptive_icon_foreground: "assets/icon.png"
```

---

## 📲 APK GÉNÉRÉ

- **Chemin** : `C:\Users\flexix\Desktop\haya\build\app\outputs\flutter-apk\app-release.apk`
- **Taille** : ~46 MB
- **Installation** : Envoyer par WhatsApp/email sur le téléphone

---

## 🔖 SAUVEGARDES GIT

| Commit | Message |
|--------|---------|
| bf876aa | "Premier ecran haya fonctionnel" |
| f43e5d0 | "Ajout ecrans Historique Profil et Connexion" |
| ab564ad | "Integration PayGate - transferts actifs" |
| 5482d9a | "Interface améliorée - boutons plus grands" |
| d95021f | "Design final haya - navigation complete" |
| 29a1ffd | "Icone finale et nom Haya avec majuscule" |
| b18d0d5 | "Phase 2 - Ecran Recevoir avec QR code et partage" |

---

## 🌐 RESSOURCES EN LIGNE

| Ressource | URL |
|-----------|-----|
| Politique de confidentialité | https://coursiertogo.github.io/haya-privacy/privacy_policy.html |
| Google Play Console | https://play.google.com/console |
| GitHub Repository Privacy | https://github.com/coursiertogo/haya-privacy |
| PayGate Global | https://paygateglobal.com |

---

## ✅ ÉTAT DU PROJET

### Fait ✅
- [x] App Flutter complète avec tous les écrans
- [x] Détection automatique Tmoney/Flooz
- [x] Intégration PayGate connectée (mode démo)
- [x] Design professionnel niveau fintech
- [x] Navigation fonctionnelle (BottomNavigationBar)
- [x] Bouton cacher/afficher le solde
- [x] Avatars colorés par personne
- [x] Écran Recevoir avec QR code ✅ PHASE 2
- [x] Boutons Copier et Partager ✅ PHASE 2
- [x] APK installé et testé sur téléphone Android
- [x] Icône officielle avec nom "Haya"
- [x] Compte Google Play Developer créé
- [x] Politique de confidentialité en ligne
- [x] Bannière Play Store 1024x500 prête
- [x] 4 captures d'écran prêtes
- [x] Git configuré avec 7 sauvegardes

### En attente ⏳
- [ ] Email Google — vérification identité (quelques jours)
- [ ] Email PayGate — activation compte Production
- [ ] Mise à jour KVK avec activité logicielle

### Phase 3 — Backend 🔲
- [ ] Backend Node.js + base de données
- [ ] Inscription réelle avec vérification OTP par SMS
- [ ] Connexion sécurisée (JWT tokens)
- [ ] Récupération vrai solde Tmoney et Flooz via API
- [ ] **"Smart Transfer" (Split Payment)** ⭐ FONCTIONNALITÉ INNOVANTE
- [ ] Publication sur Google Play Store
- [ ] Couche diaspora Stripe/Wise (envois depuis Europe en euros)
- [ ] Sécuriser clé API PayGate dans variable d'environnement

---

## ⭐ SMART TRANSFER — Fonctionnalité Innovante

> Cette fonctionnalité différencie Haya de tous les concurrents togolais !

**Concept :** L'utilisateur veut envoyer 10 000 FCFA mais a :
- 3 000 FCFA sur Flooz
- 8 000 FCFA sur Tmoney

**Haya fait automatiquement :**
- 3 000 FCFA via Flooz
- 7 000 FCFA via Tmoney
- = **10 000 FCFA en une seule opération !**

**Comment ça fonctionne :**
1. L'utilisateur tape le montant et le numéro du bénéficiaire
2. Haya vérifie les soldes sur les deux comptes
3. Haya calcule automatiquement la meilleure répartition
4. Deux transactions PayGate lancées en parallèle
5. Écran de confirmation affiche le détail du split

**Nom dans l'app :** "Envoi intelligent" ou "Smart Transfer"

**Nécessite :** Backend Phase 3 + API de consultation de solde

---

## ⚠️ POINTS IMPORTANTS À NE PAS OUBLIER

1. **🔐 Clé API PayGate** visible dans `paygate_service.dart` — à sécuriser avant publication
2. **🎮 Mode démo** actif (`_modeDemo = true`) — changer à `false` quand PayGate activé
3. **📧 Email** de contact : `haya@flexix.nl`
4. **💶 CORS** : Appels PayGate bloqués sur Chrome — OK sur vrai téléphone Android
5. **🇳🇱 KVK** : Mettre à jour avec "62010 - Ontwikkelen en produceren van software"
6. **📱 Installation téléphone** : Via WhatsApp/email (pas USB — restriction Xiaomi)
7. **💰 Frais** : PayGate prend 2.5% Flooz / 3% Tmoney par transaction
8. **💰 Solde affiché** : Fictif (125 000 FCFA) — sera remplacé par vrai solde en Phase 3

---

## 👤 INFORMATIONS DÉVELOPPEUR

- **App** : Haya
- **Email** : haya@flexix.nl
- **KVK** : Pays-Bas (eenmanszaak)
- **Compte Google Play** : coursiertogo@gmail.com
- **Account-ID Play** : 7702579219557169401
- **Pays** : Pays-Bas

