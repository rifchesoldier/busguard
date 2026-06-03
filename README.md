# 🚌 BusGuard — Application Flutter

Application mobile de suivi de bus scolaire en temps réel.
Cette version Flutter reproduit toutes les fonctionnalités de la démo web.

## 📋 Fonctionnalités

- ✅ Authentification (inscription / connexion / déconnexion)
- ✅ Tableau de bord avec statistiques
- ✅ Carte Google Maps avec position des bus en direct
- ✅ Gestion des enfants (ajout / suppression / liste)
- ✅ Système d'alertes (pickup / dropoff / retard)
- ✅ Profil utilisateur modifiable
- ✅ Notifications locales
- ✅ Connexion au même backend Lovable Cloud (Supabase) que la version web

## 🚀 Installation

### Prérequis
- Flutter SDK 3.19+
- Android Studio ou VS Code
- Un émulateur Android/iOS ou un appareil physique

### Étapes

```bash
# 1. Aller dans le dossier
cd busguard_flutter

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

## 🗺️ Configuration Google Maps

Pour que la carte fonctionne, ajoutez votre clé Google Maps API :

### Android
`android/app/src/main/AndroidManifest.xml` — dans `<application>` :
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="VOTRE_CLE_GOOGLE_MAPS"/>
```

### iOS
`ios/Runner/AppDelegate.swift` :
```swift
import GoogleMaps
GMSServices.provideAPIKey("VOTRE_CLE_GOOGLE_MAPS")
```

## 📂 Structure

```
lib/
├── main.dart                 # Point d'entrée
├── models/                   # Profile, Child, Bus, Alert
├── services/                 # auth, supabase, location, notifications
├── screens/                  # splash, auth/, dashboard, map, children, alerts, profile
├── widgets/                  # logo, stat_card, bus_card, child_card
└── utils/                    # constants, theme
```

## 🔐 Backend

L'app se connecte automatiquement au backend Lovable Cloud existant
(voir `lib/utils/constants.dart`). Les tables utilisées :
- `profiles`, `children`, `buses`, `alerts`

## 🎨 Design

- Couleur principale : **Navy `#1E2761`**
- Couleur accent : **Yellow `#FFC107`**
- Material 3
