import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_model.dart';
import '../../../core/services/storage_service.dart';

class PlayerNotifier extends StateNotifier<PlayerModel> {
  PlayerNotifier() : super(PlayerModel.initial()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final data = await StorageService.loadPlayerData();
    if (data != null) {
      state = PlayerModel.fromJson(data);
    }
  }

  void _save() {
    StorageService.savePlayerData(state.toJson());
  }

  void addCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
    _save();
  }

  void spendCoins(int amount) {
    if (state.coins >= amount) {
      state = state.copyWith(coins: state.coins - amount);
      _save();
    }
  }

  void addCrystals(int amount) {
    state = state.copyWith(crystals: state.crystals + amount);
    _save();
  }

  void addXP(int amount) {
    int newXP = state.xp + amount;
    int newLevel = state.level;
    int xpNeeded = newLevel * 100;

    while (newXP >= xpNeeded) {
      newXP -= xpNeeded;
      newLevel++;
      xpNeeded = newLevel * 100;
    }

    WizardTitle newTitle = state.title;
    if (newLevel >= 40) {
      newTitle = WizardTitle.grandWizard;
    } else if (newLevel >= 25) {
      newTitle = WizardTitle.archmage;
    } else if (newLevel >= 15) {
      newTitle = WizardTitle.mage;
    } else if (newLevel >= 5) {
      newTitle = WizardTitle.spellcaster;
    }

    state = state.copyWith(
      level: newLevel,
      xp: newXP,
      title: newTitle,
      maxHealth: 100.0 + (newLevel * 15),
      maxMana: 80.0 + (newLevel * 10),
      magicPower: 25.0 + (newLevel * 5),
    );
    _save();
  }

  bool upgradeHealth() {
    final cost = state.healthLevel * 200;
    if (state.coins >= cost) {
      state = state.copyWith(
        coins: state.coins - cost,
        healthLevel: state.healthLevel + 1,
        maxHealth: state.maxHealth + 20.0,
      );
      _save();
      return true;
    }
    return false;
  }

  bool upgradeMagic() {
    final cost = state.magicLevel * 250;
    if (state.coins >= cost) {
      state = state.copyWith(
        coins: state.coins - cost,
        magicLevel: state.magicLevel + 1,
        magicPower: state.magicPower + 8.0,
      );
      _save();
      return true;
    }
    return false;
  }

  bool upgradeMana() {
    final cost = state.manaLevel * 180;
    if (state.coins >= cost) {
      state = state.copyWith(
        coins: state.coins - cost,
        manaLevel: state.manaLevel + 1,
        maxMana: state.maxMana + 15.0,
      );
      _save();
      return true;
    }
    return false;
  }

  bool upgradeDefense() {
    final cost = state.defenseLevel * 220;
    if (state.coins >= cost) {
      state = state.copyWith(
        coins: state.coins - cost,
        defenseLevel: state.defenseLevel + 1,
        defense: state.defense + 3.0,
      );
      _save();
      return true;
    }
    return false;
  }
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerModel>((ref) {
  return PlayerNotifier();
});
