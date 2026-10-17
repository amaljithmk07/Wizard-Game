/// Compile-time flag to run the application in offline Demo Mode.
///
/// Start with `--dart-define=DEMO_MODE=true` to enable:
/// - No Socket connections or attempts to connect to backend.
/// - Local simulated mock rooms, players, and game progression.
/// - Full offline navigation from Name -> Rooms -> Lobby -> Game -> Results.
const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

/// State holder for backend server URL and runtime demo toggle.
class AppConfig {
  static bool _runtimeDemoMode = false;

  /// Default production server on Render
  static const String defaultServerUrl = 'wss://wizard-game-sk6k.onrender.com';

  static String _serverUrl = defaultServerUrl;
  static String get serverUrl => _serverUrl;

  static void setServerUrl(String url) {
    _serverUrl = url.trim();
  }

  static bool get isDemoMode => demoMode || _runtimeDemoMode;

  static void enableRuntimeDemo() {
    _runtimeDemoMode = true;
  }

  static void resetRuntimeDemo() {
    _runtimeDemoMode = false;
  }
}
