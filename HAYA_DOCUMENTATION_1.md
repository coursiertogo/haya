# 📱 HAYA — Documentation Complète du Projet
> Dernière mise à jour : 26 avril 2026

---

## 🎯 CONCEPT

- **Nom** : Haya (expression burkinabè = "allez, c'est parti")
- **Slogan** : "Envoie. C'est parti."
- **Couleurs** : Bleu nuit `#0D0D2B` + Orange `#F97316`
- **Package** : `com.flexix.haya`
- **Cible** : Diaspora togolaise aux Pays-Bas + utilisateurs locaux au Togo

---

## 👤 INFORMATIONS DÉVELOPPEUR

- **Développeur** : Koami Azanleko
- **Entreprise** : Flexix
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
| Node.js | LTS | Installé |
| VS Code | Dernière version | Installé |
| Git | Dernière version | Installé |

### Chemins importants

| Projet | Chemin |
|--------|--------|
| App Flutter | `C:\Users\flexix\Desktop\haya\` |
| Backend Node.js | `C:\Users\flexix\Desktop\haya-backend\` |
| Fichier principal | `C:\Users\flexix\Desktop\haya\lib\main.dart` |
| Clé signing Android | `C:\Users\flexix\Desktop\haya\haya-release.jks` |

---

## ⌨️ COMMANDES IMPORTANTES

### Flutter
```bash
# Aller dans le projet
cd C:\Users\flexix\Desktop\haya

# Lancer sur Chrome (debug)
flutter run
# → choisir [2] Chrome

# Lancer sur téléphone Android (câble USB)
flutter devices                        # Voir les appareils connectés
flutter run -d DEVICE_ID              # Lancer sur le téléphone

# Générer APK debug (test téléphone)
flutter build apk --debug
# Fichier : build\app\outputs\flutter-apk\app-debug.apk

# Générer APK release (production)
flutter build apk --release
# Fichier : build\app\outputs\flutter-apk\app-release.apk

# Générer AAB (Play Store)
flutter build appbundle --release
# Fichier : build\app\outputs\bundle\release\app-release.aab

# Installer dépendances
flutter pub get

# Ajouter un package
flutter pub add NOM_PACKAGE
```

### Backend
```bash
# Aller dans le projet
cd C:\Users\flexix\Desktop\haya-backend

# Lancer en développement (avec rechargement auto)
npm run dev

# Lancer en production
npm start

# Installer dépendances
npm install
```

### Git (sauvegarde)
```bash
# Sauvegarder Flutter
cd C:\Users\flexix\Desktop\haya
git add .
git commit -m "message"
git push

# Sauvegarder Backend
cd C:\Users\flexix\Desktop\haya-backend
git add .
git commit -m "message"
git push
```

---

## 📁 STRUCTURE PROJET FLUTTER

```
C:\Users\flexix\Desktop\haya\
├── lib\
│   ├── main.dart                ← Code principal (TOUS les écrans)
│   ├── feexpay_service.dart     ← Service FeexPay (mode sandbox)
│   └── notchpay_service.dart   ← Service Notchpay (prêt à brancher)
├── assets\
│   └── icon.png                 ← Icône officielle Haya
├── android\
│   └── app\build.gradle.kts    ← Config signing Android
├── pubspec.yaml                 ← Dépendances + version: 1.0.0+3
└── haya-release.jks             ← Clé signing (MDP: haya12345, alias: haya)
```

### Packages utilisés
| Package | Usage |
|---------|-------|
| `http` | Appels API backend |
| `url_launcher` | Ouvrir WhatsApp, SMS, liens |
| `shared_preferences` | Sauvegarder PIN, numéros, préférences |
| `share_plus` | Partager reçus |
| `qr_flutter` | QR code dans ReceiveScreen |

---

## 📁 STRUCTURE PROJET BACKEND

```
C:\Users\flexix\Desktop\haya-backend\
├── controllers\
│   ├── authController.js        ← Inscription + Connexion JWT
│   └── transactionController.js ← Créer/lire transactions
├── routes\
│   ├── authRoutes.js            ← Routes /api/auth
│   └── transactionRoutes.js     ← Routes /api/transactions
├── index.js                     ← Serveur Express principal
├── database.js                  ← Connexion Supabase (family:4 IPv4)
├── .env                         ← Variables d'environnement (NON pushé sur GitHub)
└── package.json                 ← Dépendances Node.js
```

### Variables d'environnement (.env)
```env
DATABASE_URL=postgresql://postgres.cxkptqcvddrxrqqawfgn:ynHmnNSB8hqVeTop@aws-0-eu-west-1.pooler.supabase.com:5432/postgres
JWT_SECRET=haya_secret_key_2026
PORT=3000
```

---

## 🌐 URLS ET RESSOURCES EN LIGNE

| Ressource | URL |
|-----------|-----|
| **Backend production** | https://haya-backend-vf5l.onrender.com |
| **Site web Haya** | https://haya.flexix.nl |
| **Page de paiement** | https://haya.flexix.nl/pay.html |
| **Politique de confidentialité** | https://coursiertogo.github.io/haya-privacy/privacy_policy.html |
| **GitHub Flutter** | https://github.com/coursiertogo/haya |
| **GitHub Backend** | https://github.com/coursiertogo/haya-backend |
| **GitHub Site web** | https://github.com/coursiertogo/haya-website |
| **Google Play Console** | https://play.google.com/console |
| **Supabase Dashboard** | https://supabase.com/dashboard/project/cxkptqcvddrxrqqawfgn |
| **Render Dashboard** | https://dashboard.render.com |

---

## 🗄️ BASE DE DONNÉES SUPABASE

- **Projet ID** : `cxkptqcvddrxrqqawfgn`
- **Region** : `aws-0-eu-west-1` (Irlande)
- **Pooler host** : `aws-0-eu-west-1.pooler.supabase.com`
- **User** : `postgres.cxkptqcvddrxrqqawfgn`
- **Mot de passe DB** : `ynHmnNSB8hqVeTop`
- **Port** : `5432`

### Tables
| Table | Description |
|-------|-------------|
| `users` | Utilisateurs (nom, prénom, téléphone, mot_de_passe hashé, pin) |
| `transactions` | Historique des transferts (expediteur_id, telephone_destinataire, montant, frais, operateur, statut, reference) |

---

## 🔌 ROUTES API BACKEND

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/auth/inscription` | POST | Créer un compte | ✅ |
| `/api/auth/connexion` | POST | Se connecter (retourne JWT) | ✅ |
| `/api/transactions` | POST | Créer une transaction | ✅ |
| `/api/transactions/:id` | GET | Historique d'un utilisateur | ✅ |
| `/api/transactions/stats/:id` | GET | Statistiques | ✅ |
| `/api/auth/otp` | POST | Envoyer OTP SMS | 🔜 À faire |
| `/api/auth/reinitialiser-mot-de-passe` | POST | Reset mot de passe | 🔜 À faire |

---

## 📱 ÉCRANS DE L'APP

| Écran | Description | Statut |
|-------|-------------|--------|
| `SplashScreen` | Animation logo 2 secondes | ✅ |
| `LoginScreen` | Connexion/inscription + validation + mot de passe oublié | ✅ |
| `HomeScreen` | Accueil + menu KA (profil/paramètres/déconnexion) | ✅ |
| `SendScreen` | Envoi avec PIN + confirmation 5 sec + statut temps réel | ✅ |
| `ReceiveScreen` | QR code + partage WhatsApp/SMS | ✅ |
| `HistoryScreen` | Historique réel depuis backend + filtres | ✅ |
| `ProfileScreen` | Profil simplifié + numéros + actions rapides | ✅ |
| `ParametresScreen` | PIN, numéros, notifications, mode sombre, conversion EUR | ✅ |
| `ContactsScreen` | Contacts favoris | ✅ |
| `PaymentRequestScreen` | Demande de paiement (numéros profil uniquement) | ✅ |
| `PinScreen` | Clavier PIN 4 chiffres avec shake si erreur | ✅ |
| `SuccessScreen` | Succès avec reçu partageable | ✅ |
| `MotDePasseOublieScreen` | 3 étapes : téléphone → OTP → nouveau MDP | ✅ (OTP démo) |

---

## 🏗️ CLASSES IMPORTANTES DANS MAIN.DART

| Classe | Rôle |
|--------|------|
| `UserManager` | Données utilisateur connecté (nom, prénom, tel) — persistant SharedPreferences |
| `NumerosManager` | Numéros Tmoney/Flooz + préférences — persistant SharedPreferences |
| `PinManager` | Gestion PIN de transfert — persistant SharedPreferences |
| `HayaApiService` | Appels API backend (transactions, historique) |
| `TauxChangeService` | Taux EUR/FCFA en temps réel |
| `ThemeManager` | Mode sombre/clair |
| `ContactsManager` | Contacts favoris |

---

## 🔑 INFORMATIONS SIGNING ANDROID

```
Fichier  : haya-release.jks
Mot de passe : haya12345
Alias    : haya
```

⚠️ **Ne jamais partager ce fichier ni le mot de passe.**

---

## 💳 INTÉGRATION PAIEMENT

### FeexPay (`lib/feexpay_service.dart`)
- **URL Tmoney** : `https://api-v2.feexpay.me/api/transactions/public/requesttopay/togocom_tg`
- **URL Flooz** : `https://api-v2.feexpay.me/api/transactions/public/requesttopay/moov_tg`
- **Shop ID** : `yl8mn0u9Lc0R7p6`
- **Mode** : `_modeSandbox = true` ← passer à `false` après validation
- **Statut** : 🟡 Contrat soumis 23/04/2026 — en attente validation

### Notchpay (`lib/notchpay_service.dart`)
- **URL** : `https://api.notchpay.co/payments`
- **Canal Tmoney** : `tg.togocom` — Canal Flooz : `tg.moov`
- **Mode** : `_modeSandbox = true` ← passer à `false` après activation
- **Statut** : 🟡 Documents fournis 23/04/2026 — en attente activation

### Pour activer un opérateur en production
1. Obtenir la clé API de production
2. Changer `_modeSandbox = false` dans le fichier service
3. Renseigner la vraie clé API
4. Tester avec un vrai transfert de 100 FCFA

---

## 🔐 SÉCURITÉ

### SharedPreferences — données sauvegardées
| Clé | Contenu |
|-----|---------|
| `pin` | Code PIN hashé |
| `pin_defini` | Boolean PIN créé |
| `num_tmoney` | Numéro Tmoney |
| `num_flooz` | Numéro Flooz |
| `notifications_on` | Boolean notifications |
| `conversion_eur_on` | Boolean affichage EUR |
| `user_nom` | Nom utilisateur |
| `user_prenom` | Prénom utilisateur |
| `user_telephone` | Téléphone |
| `user_id` | ID utilisateur backend |

### Règles importantes
- ⚠️ Mode sandbox actif dans `feexpay_service.dart` ET `notchpay_service.dart`
- ⚠️ Fichier `.env` backend NON pushé sur GitHub (dans .gitignore)
- ⚠️ `haya-release.jks` à conserver précieusement — sans lui impossible de mettre à jour l'app
- PIN demandé uniquement au premier transfert, puis à chaque transfert suivant
- CORS bloqué sur Chrome — normal, fonctionne sur vrai téléphone Android

---

## 🌍 DÉTECTION OPÉRATEURS TOGO

```dart
const tmoneySuffixes = ['70', '71', '90', '91', '92', '93'];
const floozPrefixes  = ['79', '94', '95', '96', '97', '98', '99'];
```

---

## 💰 STRUCTURE DES FRAIS HAYA

- **Frais** : 1% du montant envoyé
- **Minimum de frais** : 10 FCFA
- **Minimum de transfert** : 1 000 FCFA

---

## 📬 PAGE DE PAIEMENT (pay.html)

**URL** : `https://haya.flexix.nl/pay.html`

### Paramètres URL
| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `n` | Numéro de réception | `90123456` |
| `m` | Montant en FCFA | `5000` |
| `nom` | Nom de l'expéditeur (encodé) | `Koami%20Azanleko` |
| `obj` | Objet du paiement (encodé) | `Loyer` |
| `op` | Opérateur (`tmoney` ou `flooz`) | `tmoney` |
| `ref` | Référence unique | `REQ-123456` |
| `mode` | `preview` pour l'expéditeur | `preview` |

### Comportement
- **mode=preview** : Bouton orange "Envoyer cette demande" — pour l'expéditeur
- **mode normal** : Bouton "Payer avec Haya" + "Partager" — pour le destinataire
- **Après paiement** : Badge "✅ Payé" + date, bouton "Déjà payé" gris et inactif

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
| FeexPay | 🟡 En attente | Contrat soumis 23/04/2026 |
| Notchpay | 🟡 En attente | Documents fournis 23/04/2026 |
| FedaPay | 🟡 Email envoyé | Basé au Bénin — couvre Togo |
| CinetPay | ❌ Refusé | Exige entreprise en Afrique |
| Pawapay | ❌ Togo non couvert | — |

---

## 🚀 PROCHAINES ÉTAPES

| Tâche | Priorité |
|-------|----------|
| Attendre activation FeexPay/Notchpay | 🔴 Bloquant |
| OTP SMS réel (Africa's Talking) | 🟡 Moyenne |
| Verrouillage automatique après 2 min | 🟡 Moyenne |
| Historique dans HomeScreen | 🟡 Moyenne |
| Sécuriser clés API (.env) avant production | 🔴 Avant production |
| Générer AAB + soumettre Play Store v1.0.1 | 🟡 Après paiement réel |
| 12 testeurs Gmail pour accès production | 🟡 Moyenne |

---

## 🌍 EXPANSION PAYS — PHASE 2

### Bénin 🇧🇯
- **Opérateurs** : MTN Mobile Money, Moov Money
- **Indicatif** : +229
- **FedaPay** : ✅ Couvert — **Notchpay** : ✅ Couvert

### Burkina Faso 🇧🇫
- **Opérateurs** : Orange Money, Moov Money
- **Indicatif** : +226
- **Notchpay** : ⚠️ À vérifier

---

## 💡 VISION PRODUIT

| Phase | Fonctionnalité | Statut |
|-------|---------------|--------|
| 1 | FCFA → FCFA Togo (Tmoney/Flooz) | 🟡 En cours |
| 2 | EUR → FCFA diaspora Pays-Bas | 🔜 Phase 2 |
| 3 | Expansion Bénin + Burkina Faso | 🔜 Phase 3 |
| 4 | Smart Transfer Tmoney ↔ Flooz | 🔜 Phase 4 |
