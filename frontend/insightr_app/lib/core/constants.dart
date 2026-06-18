/// API and app-wide constants for Insightr.
/// For Android emulator: localhost = 10.0.2.2
/// For physical device: replace with your machine's LAN IP
class AppConstants {
  // Backend base URL. Can be overridden via --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  // API endpoints
  static const String feedEndpoint = '/api/feed';
  static const String processEndpoint = '/api/process';
  static const String statusEndpoint = '/api/status';
  static const String entriesEndpoint = '/api/entries';
  static const String todoEndpoint = '/api/todo';
  static const String searchEndpoint = '/api/search';
  static const String conceptsEndpoint = '/api/concepts';
  static const String collectionsEndpoint = '/api/collections';
  static const String exportEndpoint = '/api/export';

  // Shared prefs keys
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';

  // Polling interval for processing status
  static const Duration pollingInterval = Duration(seconds: 2);

  // Feed page size
  static const int feedLimit = 50;
}
