import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _playerKey = 'wizard_player_data';
  static const String _spellsKey = 'wizard_spells_data';
  static const String _equipmentKey = 'wizard_equipment_data';
  static const String _progressKey = 'wizard_chapter_progress';
  static const String _settingsKey = 'wizard_game_settings';

  static Future<bool> savePlayerData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_playerKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_playerKey);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> saveSpellsData(List<Map<String, dynamic>> spells) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_spellsKey, jsonEncode(spells));
  }

  static Future<List<Map<String, dynamic>>?> loadSpellsData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_spellsKey);
    if (str != null) {
      final List decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }

  static Future<bool> saveEquipmentData(Map<String, dynamic> equipment) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_equipmentKey, jsonEncode(equipment));
  }

  static Future<Map<String, dynamic>?> loadEquipmentData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_equipmentKey);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> saveChapterProgress(int chapter, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(
        _progressKey, jsonEncode({'chapter': chapter, 'level': level}));
  }

  static Future<Map<String, dynamic>> loadChapterProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_progressKey);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return {'chapter': 1, 'level': 1};
  }

  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_settingsKey, jsonEncode(settings));
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_settingsKey);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return {'music': 0.8, 'sfx': 1.0, 'haptics': true};
  }
}
