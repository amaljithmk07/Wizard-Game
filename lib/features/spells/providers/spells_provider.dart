import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spell_model.dart';

class SpellsNotifier extends StateNotifier<List<SpellModel>> {
  SpellsNotifier() : super(SpellModel.initialSpells());

  void toggleEquip(String spellId) {
    state = [
      for (final s in state)
        if (s.id == spellId) s.copyWith(isEquipped: !s.isEquipped) else s,
    ];
  }

  bool upgradeSpell(
      String spellId, int availableCoins, Function(int) deductCoins) {
    final index = state.indexWhere((s) => s.id == spellId);
    if (index != -1) {
      final spell = state[index];
      if (spell.level < spell.maxLevel && availableCoins >= spell.upgradeCost) {
        deductCoins(spell.upgradeCost);
        final updated = spell.copyWith(level: spell.level + 1);
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index) updated else state[i],
        ];
        return true;
      }
    }
    return false;
  }
}

final spellsProvider =
    StateNotifierProvider<SpellsNotifier, List<SpellModel>>((ref) {
  return SpellsNotifier();
});
