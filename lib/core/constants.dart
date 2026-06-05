class AppConstants {
  static const String appName = 'BusGuard';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const double dakarLat = 14.7167;
  static const double dakarLng = -17.4677;

  static const int gpsUpdateIntervalSec = 3;
  static const int etaRefreshIntervalSec = 30;
  static const int gpsSignalLostSec = 30;

  static const String privacyPolicyUrl = 'https://busguard.sn/privacy';
}
