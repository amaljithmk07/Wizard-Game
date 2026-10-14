/// Compile-time flag to run the application in offline Demo Mode.
///
/// Start with `--dart-define=DEMO_MODE=true` to enable:
/// - No Socket.IO connections or attempts to connect to localhost.
/// - Local simulated mock rooms, players, and game progression.
/// - Full offline navigation from Name -> Rooms -> Lobby -> Game -> Results.
const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

/// State holder for runtime demo toggle if user chooses to try demo mode
/// when backend connection fails in normal mode.
class AppConfig {
  static bool _runtimeDemoMode = false;

  static bool get isDemoMode => demoMode || _runtimeDemoMode;

  static void enableRuntimeDemo() {
    _runtimeDemoMode = true;
  }

  static void resetRuntimeDemo() {
    _runtimeDemoMode = false;
  }
}
