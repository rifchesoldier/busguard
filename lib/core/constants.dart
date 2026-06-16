class AppConstants {
  static const String appName = 'BusGuard';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  /// Clé Google Maps utilisée pour le fallback Directions API côté client.
  /// Remplace cette valeur par ta vraie clé (ou injecte-la via --dart-define).
  static const String googleMapsApiKey = String.fromEnvironment(
    'AIzaSyBcr0SBSOBX7V3-0jMKpWat2Uka7tYqxNw',
    defaultValue: 'AIzaSyBcr0SBSOBX7V3-0jMKpWat2Uka7tYqxNw',
  );

  static const double dakarLat = 14.7167;
  static const double dakarLng = -17.4677;

  static const int gpsUpdateIntervalSec = 3;
  static const int etaRefreshIntervalSec = 30;
  static const int gpsSignalLostSec = 30;

  static const String privacyPolicyUrl = 'https://busguard.sn/privacy';
}