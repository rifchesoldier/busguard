# BusGuard v2.0

Application de suivi de transport scolaire en temps réel pour Dakar — parents, chauffeurs et administrateurs.

## Architecture

| Composant | Technologie |
|-----------|-------------|
| Mobile (Parent + Chauffeur) | Flutter / Dart |
| Temps réel & Auth | Firebase (Firestore, Auth, FCM) |
| API relationnelle | Laravel 11 + SQLite/MySQL |
| Admin Web | Laravel Blade + Tailwind |
| Cartographie | flutter_map (OpenStreetMap) |
| ETA | Google Maps Distance Matrix API |

## Structure du projet

```
busguard/
├── lib/                 # Application Flutter
├── backend/             # API Laravel 11 + Admin Web
├── firebase/            # Règles Firestore
└── assets/
```

## Démarrage rapide

### Backend Laravel

```bash
cd backend
composer install
php artisan migrate --seed
php artisan serve
```

Admin web : http://localhost:8000/admin/login

**Comptes démo :**
| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Super Admin | admin@busguard.sn | BusGuard2024! |
| Admin École | ecole@busguard.sn | BusGuard2024! |
| Chauffeur | chauffeur@busguard.sn | BusGuard2024! |
| Parent | parent@busguard.sn | BusGuard2024! |

### Application Flutter

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

> Sur appareil physique, remplacez `127.0.0.1` par l'IP de votre machine. Ou bien vous pouvez le lancer sur votre machine physique

### Firebase (production)

1. Créez un projet Firebase Console
2. Exécutez `flutterfire configure`
3. Déployez les règles : `firebase deploy --only firestore:rules`
4. Ajoutez `google-services.json` (Android) et `GoogleService-Info.plist` (iOS)

Sans Firebase, l'app fonctionne en **mode démo** avec simulation GPS.

### Variables d'environnement backend (.env)

```env
GOOGLE_MAPS_API_KEY=your_key
FCM_SERVER_KEY=your_fcm_server_key
```

## Fonctionnalités

### Parent
- Carte temps réel avec bus, tracé et ETA
- États : non démarré, absent, à bord, arrivé, alerte trafic
- Notifications push (FCM)
- Mode hors-ligne avec cache Firestore
- Consentement RGPD à l'inscription

### Chauffeur
- Sélection véhicule et type de tournée (matin/soir)
- GPS arrière-plan (mise à jour 3s)
- Feuille de présence par arrêt
- Signalement incidents (embouteillage, accident, panne)
- File d'attente hors-ligne pour les présences

### Administrateur (Web)
- Gestion écoles, bus, itinéraires, arrêts, élèves, chauffeurs
- Historique des présences + export CSV
- Authentification 2FA
- Dashboard temps réel

## Licence

Projet BusGuard — Transport scolaire sécurisé, Dakar Sénégal.
