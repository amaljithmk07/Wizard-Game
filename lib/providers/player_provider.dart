import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final playerNameProvider =
    StateNotifierProvider<PlayerNameNotifier, String>((ref) {
  return PlayerNameNotifier();
});

class PlayerNameNotifier extends StateNotifier<String> {
  PlayerNameNotifier() : super('Amal') {
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('player_name');
      if (savedName != null && savedName.trim().isNotEmpty) {
        state = savedName.trim();
      }
    } catch (_) {}
  }

  Future<void> setName(String name) async {
    state = name.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('player_name', name.trim());
    } catch (_) {}
  }
}
