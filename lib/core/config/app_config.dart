/// Central application configuration for online multiplayer.
class AppConfig {
  /// Default production server on Render
  static const String defaultServerUrl = 'wss://wizard-game-sk6k.onrender.com';

  static String _serverUrl = defaultServerUrl;
  static String get serverUrl => _serverUrl;

  static void setServerUrl(String url) {
    _serverUrl = url.trim();
  }

  /// Demo/mock mode is disabled for real live multiplayer
  static bool get isDemoMode => false;

  static void enableRuntimeDemo() {}
  static void resetRuntimeDemo() {}
}
