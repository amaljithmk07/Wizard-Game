# GAME ARCHITECTURE — Wizard Fantasy Mobile RPG

## 1. Directory Structure Specification (`lib/`)

```
lib/
├── main.dart                       (Root ProviderScope & MaterialApp)
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         (Midnight Purple, Arcane Blue, Fire Orange, Gold)
│   │   ├── app_typography.dart     (Cinzel display + Inter body)
│   │   └── app_theme.dart          (Material 3 dark fantasy theme)
│   ├── services/
│   │   ├── storage_service.dart    (Hive/SharedPreferences persistence)
│   │   ├── audio_service.dart      (BGM, SFX & pitch modulation)
│   │   └── haptic_service.dart     (Mobile tactile haptics)
│   └── utils/
│       ├── formatters.dart
│       └── constants.dart
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── home_screen.dart    (3D/Animated Wizard hero preview + CTA)
│   │   │   └── widgets/
│   ├── battle/
│   │   ├── data/                   (Chapter & Level definitions)
│   │   ├── presentation/
│   │   │   ├── battle_select_screen.dart
│   │   │   └── boss_arena_screen.dart
│   ├── game_engine/
│   │   ├── components/             (PlayerWizard, EnemyComponent, ProjectileComponent, BossComponent)
│   │   ├── systems/                (SpellCollisionSystem, LootDropSystem, ParticleSystem)
│   │   └── game_view.dart          (Flame GameWidget integration)
│   ├── wizard/
│   │   ├── data/                   (Wizard stats & titles: Apprentice -> Grand Wizard)
│   │   └── presentation/
│   │       └── wizard_profile_screen.dart
│   ├── spells/
│   │   ├── models/                 (SpellModel, ElementType, Rarity)
│   │   └── presentation/
│   │       └── spell_book_screen.dart
│   ├── inventory/
│   │   ├── models/                 (EquipmentModel, ItemSlot)
│   │   └── presentation/
│   │       └── inventory_screen.dart
│   ├── quests/
│   ├── achievements/
│   ├── shop/
│   └── settings/
```

---

## 2. Core Data Models

### 2.1 Player Model (`PlayerModel`)
- `id`: String
- `name`: String
- `level`: int
- `xp`: int
- `title`: WizardTitle (Apprentice, Spellcaster, Mage, Archmage, GrandWizard)
- `coins`: int
- `crystals`: int
- `health`: double (Max Health)
- `mana`: double (Max Mana)
- `magicPower`: double
- `defense`: double
- `critChance`: double
- `moveSpeed`: double
- `manaRegen`: double
- `cooldownReduction`: double

### 2.2 Spell Model (`SpellModel`)
- `id`: String
- `name`: String
- `description`: String
- `element`: ElementType (fire, ice, lightning, nature, dark, arcane, healing)
- `damage`: double
- `manaCost`: double
- `cooldown`: double (seconds)
- `level`: int
- `maxLevel`: int
- `rarity`: Rarity (common, rare, epic, legendary, mythic)
- `effectType`: SpellEffectType (projectile, areaOfEffect, buff, healing, shield, teleport)

---

## 3. State Management Architecture (Riverpod)

- **`playerStateProvider`**: StateNotifier for player level, XP, coins, crystals, and stats.
- **`spellsProvider`**: StateNotifier for unlocked and equipped spells.
- **`inventoryProvider`**: StateNotifier for equipment items & equipped gear.
- **`battleStateProvider`**: Game loop combat state (current wave, active health/mana, combo count).
- **`questStateProvider`**: Daily/weekly quest progress.

---

## 4. Game Engine Integration Strategy
- **Application Layer**: Flutter Widgets (Home, Spells, Inventory, Shop, Dialogs, UI overlays).
- **Combat Layer**: `FlameGame` canvas engine with custom components:
  - `WizardComponent`: Controlled by virtual joystick / touch target.
  - `SpellProjectileComponent`: Sprite animation + trail particle effect + AABB collision detection.
  - `EnemyComponent`: AI pathfinding towards player, attack telegraphing, damage floaters.
  - `BossComponent`: Multi-phase state machine (Phase 1 basic attack -> Phase 2 minion summon -> Phase 3 AOE burst).
