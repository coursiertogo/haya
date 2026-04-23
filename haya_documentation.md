# 📱 HAYA — Documentation Complète du Projet
> Dernière mise à jour : 23 avril 2026

---

## 🎯 CONCEPT

- **Nom** : Haya (expression burkinabè = "allez, c'est parti")
- **Slogan** : "Envoie. C'est parti."
- **Couleurs** : Bleu nuit `#0D0D2B` + Orange `#F97316`
- **Package** : `com.flexix.haya`
- **Cible** : Diaspora togolaise aux Pays-Bas + utilisateurs locaux au Togo
- **Modèle** : Transferts mobiles Tmoney ↔ Flooz au Togo

---

## 👤 INFORMATIONS DÉVELOPPEUR

- **Développeur** : Koami Azanleko
- **Adresse** : Van Dekemanlaan 8, Heerenveen, Pays-Bas
- **KVK** : 95999698
- **Email** : haya@flexix.nl
- **Compte Google Play** : coursiertogo@gmail.com
- **Account-ID Play** : 7702579219557169401

---

## 🔧 ENVIRONNEMENT DE DÉVELOPPEMENT

| Outil | Version | Emplacement |
|-------|---------|-------------|
| Flutter | 3.41.6 | `C:\flutter\bin` |
| Projet Flutter | - | `C:\Users\flexix\Desktop\haya` |
| Projet Backend | - | `C:\Users\flexix\Desktop\haya-backend` |
| Android Studio | Panda 3 / 2025.3.3 | Installé |
| VS Code | Dernière version | Installé |

### Commandes Flutter
```bash
flutter run                      # Lancer l'app (choisir Chrome)
flutter run -d DEVICE_ID         # Lancer sur téléphone Android
flutter build apk --release      # Générer l'APK final
flutter build appbundle          # Générer AAB pour Play Store
git add .                        # Préparer sauvegarde
git commit -m "message"          # Sauvegarder
```

### Commandes Backend
```bash
cd C:\Users\flexix\Desktop\haya-backend
npm run dev                      # Lancer en développement
npm start                        # Lancer en production
```

---

## 📁 STRUCTURE PROJET FLUTTER

```
C:\Users\flexix\Desktop\haya\
├── lib\
│   ├── main.dart                ← Code principal (tous les écrans)
│   ├── feexpay_service.dart     ← Service FeexPay (mode sandbox)
│   └── notchpay_service.dart   ← Service Notchpay (prêt à brancher)
├── assets\
│   └── icon.png                 ← Icône officielle
├── android\app\build.gradle.kts ← Config signing
├── pubspec.yaml                 ← version: 1.0.0+3
└── haya-release.jks             ← Clé signing (MDP: haya12345, alias: haya)
```

## 📁 STRUCTURE PROJET BACKEND

```
C:\Users\flexix\Desktop\haya-backend\
├── controllers\
│   └── authController.js        ← Inscription + Connexion
├── routes\
│   └── authRoutes.js            ← Routes /api/auth
├── middlewares\                 ← À compléter
├── index.js                     ← Serveur Express
├── database.js                  ← Connexion Supabase
├── .env                         ← Variables d'environnement
└── package.json
```

---

## 📱 ÉCRANS DE L'APP

### Fonctionnalités implémentées ✅
1. **SplashScreen** — animation logo 2 secondes
2. **LoginScreen** — connexion/inscription (fictif pour l'instant)
3. **HomeScreen** — accueil avec transactions récentes
4. **SendScreen** — envoi avec PIN + confirmation 5 sec + statut temps réel
5. **ReceiveScreen** — QR code + partage WhatsApp/SMS
6. **HistoryScreen** — historique avec filtres + partage reçu ✅ AMÉLIORÉ
7. **ProfileScreen** — profil + numéros Tmoney/Flooz + bouton Paramètres ✅ AMÉLIORÉ
8. **ParametresScreen** — écran paramètres complet ✅ NOUVEAU
9. **ContactsScreen** — contacts favoris
10. **PaymentRequestScreen** — demande de paiement WhatsApp/SMS
11. **PinScreen** — clavier PIN 4 chiffres avec shake si erreur
12. **SuccessScreen** — succès avec reçu partageable ✅ AMÉLIORÉ
13. **_TransfertProgressDialog** — 4 étapes en temps réel
14. **_ConfirmationCountdownDialog** — compte à rebours 5 secondes

---

## 💰 STRUCTURE DES FRAIS HAYA

- **Montant minimum** : 1 000 FCFA
- **Frais** : 1% du montant
- **Minimum de frais** : 10 FCFA

---

## 🔑 PRÉFIXES OPÉRATEURS TOGO

```dart
const tmoneySuffixes = ['70', '71', '90', '91', '92', '93'];
const floozPrefixes = ['79', '94', '95', '96', '97', '98', '99'];
```

---

## 💳 INTÉGRATION PAIEMENT — FEEXPAY

### Fichier : `lib/feexpay_service.dart`
- **URL Togocom** : `https://api-v2.feexpay.me/api/transactions/public/requesttopay/togocom_tg`
- **URL Moov** : `https://api-v2.feexpay.me/api/transactions/public/requesttopay/moov_tg`
- **Shop ID** : yl8mn0u9Lc0R7p6
- **`_modeSandbox = true`** ← à passer false après validation

### ⚠️ STATUT FEEXPAY
- Nouveau contrat soumis le 23/04/2026 — en attente de validation

---

## 💳 INTÉGRATION PAIEMENT — NOTCHPAY

### Fichier : `lib/notchpay_service.dart` ✅ Prêt
- **URL init** : `https://api.notchpay.co/payments`
- **Canal Tmoney** : `tg.togocom` — Canal Flooz : `tg.moov`
- **Devise** : `XOF`
- **`_modeSandbox = true`** ← à passer false après validation

### ⚠️ STATUT NOTCHPAY
- Compte créé le 23/04/2026 — documents fournis — en attente d'activation

---

## 🗄️ BACKEND

### Stack
- **Node.js + Express** — API REST
- **Supabase (PostgreSQL)** — Base de données hébergée en Irlande

### Routes disponibles ✅
| Route | Méthode | Description |
|-------|---------|-------------|
| `/api/auth/inscription` | POST | Créer un compte |
| `/api/auth/connexion` | POST | Se connecter |

### Routes à créer 🔜
| Route | Méthode | Description |
|-------|---------|-------------|
| `/api/transactions` | POST | Créer une transaction |
| `/api/transactions` | GET | Historique transactions |
| `/api/users/profil` | GET | Récupérer le profil |
| `/api/users/profil` | PUT | Modifier le profil |
| `/api/auth/otp` | POST | Envoyer OTP SMS |

---

## 🌐 RESSOURCES EN LIGNE

| Ressource | URL |
|-----------|-----|
| Site web Haya | https://haya.flexix.nl |
| Politique de confidentialité | https://coursiertogo.github.io/haya-privacy/privacy_policy.html |
| Google Play Console | https://play.google.com/console |
| GitHub compte | coursiertogo |

---

## 🔖 SAUVEGARDES GIT

| Commit | Message |
|--------|---------|
| bf876aa | Premier ecran haya fonctionnel |
| f43e5d0 | Ajout ecrans Historique Profil et Connexion |
| ab564ad | Integration PayGate - transferts actifs |
| b18d0d5 | Phase 2 - Ecran Recevoir avec QR code et partage |
| 763c973 | Message erreur + confirmation 5sec + mode sombre + ameliorations UI |
| dernier | Integration FeexPay sandbox + Parametres + Recu partageable |

---

## 🏪 PLAY STORE

- **Statut** : App publiée en test interne
- **Version actuelle** : 1.0.0+3
- **Prochaine version** : 1.0.1+4 (après intégration paiement réel)
- **Testeurs nécessaires** : 12 comptes Gmail pour accès production
- **Titre** : Haya - Transferts Mobile Togo
- **Catégorie** : Finance

---

## 🌍 PARTENAIRES DE PAIEMENT

| Partenaire | Statut | Notes |
|------------|--------|-------|
| FeexPay | 🟡 En attente | Contrat soumis le 23/04/2026 |
| Notchpay | 🟡 En attente | Documents fournis le 23/04/2026 |
| FedaPay | 🟡 Email envoyé | Demande éligibilité entreprise étrangère |
| CinetPay | ❌ Refusé | Exige entreprise en Afrique |
| PayGate | ⏳ Pas de réponse | Token conservé en mode démo |
| Pawapay | ❌ Togo non couvert | - |

---

## 📬 DÉMARCHES ADMINISTRATIVES

- **Uittreksel BRP** : Commandé à gemeente Heerenveen — en attente par courrier
- **KVK 95999698** : Flexix, Heerenveen, Pays-Bas

---

## 🚀 PLAN — FIN AVRIL 2026

### Progression backend ✅
- ✅ Serveur Node.js + Express
- ✅ Base de données Supabase connectée
- ✅ Inscription utilisateur (JWT + bcrypt)
- ✅ Connexion utilisateur

### À faire cette semaine
| Tâche | Priorité |
|-------|----------|
| Améliorations Flutter (liste ci-dessous) | 🔴 Haute |
| Routes transactions backend | 🔴 Haute |
| Connexion Flutter ↔ Backend | 🔴 Haute |
| OTP SMS | 🟡 Moyenne |
| Brancher Notchpay/FeexPay dès activation | 🔴 Haute |
| Tests sur téléphone Android | 🔴 Haute |
| Générer AAB + soumettre Play Store | 🟡 Moyenne |

---

## 🛠️ AMÉLIORATIONS FLUTTER À FAIRE

### 🔴 Priorité haute — Sécurité
1. **Forcer définition du PIN à la première connexion** — ne pas laisser le PIN par défaut 1234, obliger l'utilisateur à en créer un dès la première ouverture de l'app
2. **Sécuriser les clés API** — sortir les clés de `feexpay_service.dart` et `notchpay_service.dart` et les mettre dans un fichier `.env` Flutter (package `flutter_dotenv`)
3. **Verrouillage automatique** — demander le PIN après 2 minutes d'inactivité

### 🟡 Priorité moyenne — Interface
4. **Nom utilisateur dynamique** — remplacer "Koffi Ameko" et "KA" codés en dur par les vraies données du profil connecté
5. **Mention paiement générique** — changer "Securise par FeexPay" en "Securise par Haya" dans SendScreen
6. **Brancher Notchpay dans SendScreen** — remplacer les appels FeexPay par Notchpay dès activation

### 🟢 Priorité basse — Expérience utilisateur
7. **Vraie validation LoginScreen** — connecter l'écran de connexion au backend (appel API réel)
8. **Solde réel** — remplacer le message "Connectez votre compte" par le vrai solde depuis le backend
9. **Numéros dans PaymentRequestScreen** — pré-remplir automatiquement avec les numéros enregistrés dans le Profil

---

## 🌍 EXPANSION PAYS — PHASE 2

> ⚠️ Phase 1 = Togo uniquement. L'expansion se fait après stabilisation.

### Bénin 🇧🇯
- **Opérateurs** : MTN Mobile Money, Moov Money
- **FeexPay** : ✅ Couvert (1.7% PAYIN, 1% PAYOUT)
- **Notchpay** : ✅ Couvert — **Indicatif** : +229

### Burkina Faso 🇧🇫
- **Opérateurs** : Orange Money, Moov Money
- **FeexPay** : ✅ Couvert — **Notchpay** : ⚠️ À vérifier — **Indicatif** : +226

### Ce qu'il faudra faire
1. Ajouter sélecteur de pays dans l'app
2. Ajouter préfixes et indicatifs par pays
3. Adapter la détection automatique d'opérateur

---

## ⚠️ POINTS IMPORTANTS À NE PAS OUBLIER

1. **Mode sandbox actif** (`_modeSandbox = true`) dans feexpay_service.dart ET notchpay_service.dart
2. **Clé API FeexPay** dans feexpay_service.dart — à sécuriser avant production
3. **Clé API Notchpay** dans notchpay_service.dart — à renseigner dès activation
4. **Shop ID FeexPay** : yl8mn0u9Lc0R7p6
5. **PIN par défaut** : 1234 — ⚠️ À forcer au changement à la première connexion
6. **Solde affiché** : fictif — sera remplacé avec le backend
7. **CORS** : Appels API bloqués sur Chrome — OK sur vrai téléphone Android
8. **Signing key** : haya-release.jks, MDP: haya12345, alias: haya

---

## 💡 VISION PRODUIT

| Phase | Fonctionnalité | Statut |
|-------|---------------|--------|
| 1 | FCFA → FCFA Togo (Tmoney/Flooz) | 🟡 En cours |
| 2 | Smart Transfer Tmoney ↔ Flooz | 🔜 Backend |
| 3 | EUR → FCFA diaspora | 🔜 Phase 3 |
| 4 | Expansion Bénin + Burkina Faso | 🔜 Après lancement Togo |

**Roadmap frais :**
- Frais : 1% du montant — Minimum : 1 000 FCFA — Minimum de frais : 10 FCFA
