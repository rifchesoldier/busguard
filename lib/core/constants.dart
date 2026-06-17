class AppConstants {
  static const String appName = 'BusGuard';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.25:8000/api/v1',
  );

  /// Clé Google Maps — injectée via --dart-define=GOOGLE_MAPS_KEY=...
  /// ou utilisée directement comme constante pour le développement.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: 'AIzaSyBcr0SBSOBX7V3-0jMKpWat2Uka7tYqxNw',
  );

  static const double dakarLat = 14.7167;
  static const double dakarLng = -17.4677;

  static const int gpsUpdateIntervalSec = 3;
  static const int etaRefreshIntervalSec = 30;
  static const int gpsSignalLostSec = 30;

  static const String privacyPolicyUrl = 'https://busguard.sn/privacy';
}