/// Central application configuration for online multiplayer.
class AppConfig {
  /// Default production server on Render
  static const String defaultServerUrl = 'wss://wizard-game-sk6k.onrender.com';

  static String _serverUrl = defaultServerUrl;
  static String get serverUrl => _serverUrl;

  static void setServerUrl(String url) {
    _serverUrl = url.trim();
  }

  static bool _demoMode = false;
  static bool get isDemoMode => _demoMode;

  static void enableRuntimeDemo() {
    _demoMode = true;
  }

  static void resetRuntimeDemo() {
    _demoMode = false;
  }
}
