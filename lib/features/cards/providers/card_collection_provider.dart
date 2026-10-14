import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_card_model.dart';

class CardCollectionNotifier extends StateNotifier<List<GameCardModel>> {
  CardCollectionNotifier() : super(GameCardModel.presetCards());

  void upgradeCard(String id) {
    state = [
      for (final card in state)
        if (card.id == id && card.level < card.maxLevel)
          card.copyWith(
            level: card.level + 1,
            damage: card.damage * 1.2,
            defense: card.defense > 0 ? card.defense * 1.18 : 0,
            healing: card.healing > 0 ? card.healing * 1.2 : 0,
            upgradeCostCoins: (card.upgradeCostCoins * 1.4).toInt(),
          )
        else
          card
    ];
  }

  void toggleEquipCard(String id) {
    state = [
      for (final card in state)
        if (card.id == id) card.copyWith(isEquipped: !card.isEquipped) else card
    ];
  }

  void unlockCard(String id) {
    state = [
      for (final card in state)
        if (card.id == id) card.copyWith(isUnlocked: true) else card
    ];
  }
}

final cardCollectionProvider =
    StateNotifierProvider<CardCollectionNotifier, List<GameCardModel>>((ref) {
  return CardCollectionNotifier();
});
