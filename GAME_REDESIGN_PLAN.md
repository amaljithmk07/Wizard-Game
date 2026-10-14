# GAME REDESIGN PLAN — Wizard Fantasy Mobile RPG

This plan details the progressive transformation of the Wizard mobile app into a premium action RPG mobile game for iOS & Android.

---

## Priority 0 (P0) — Critical Foundation & Architecture

### P0-1: Clean Feature-First Architecture & State Management
- **Problem**: Entire game state is trapped in monolithic `main.dart` with `setState()`.
- **Why It Matters**: Prevents real-time 60 FPS combat, leads to accidental widget rebuilds, and breaks scalability.
- **Recommended Solution**: Reorganize into `lib/core/` and `lib/features/` (Home, Game Engine, Spells, Inventory, Equipment, Quests, Shop, Settings) using **Flutter Riverpod**.
- **Files Affected**: `lib/main.dart`, `lib/core/*`, `lib/features/*`
- **Expected Outcome**: Completely decoupled UI, persistent player state, and isolated 60 FPS game loop.

### P0-2: Real-Time Combat Game Engine (Flame Engine Integration)
- **Problem**: Current app only renders static card widgets.
- **Why It Matters**: Mobile action RPGs require real-time movement, spell projectile physics, collision detection, and enemy AI.
- **Recommended Solution**: Integrate `flame` & `flame_audio` for the Battle Screen arena, using virtual dual-joystick controls, projectile systems, hitboxes, and particle bursts.
- **Files Affected**: `lib/features/game_engine/`
- **Expected Outcome**: Fast, responsive, 60 FPS mobile magic combat.

### P0-3: Save & Persistence System (Hive / SharedPreferences)
- **Problem**: No data saving.
- **Why It Matters**: Players lose all level-up progress, coins, crystals, and equipment on app exit.
- **Recommended Solution**: Implement local JSON / Hive database for player stats, unlocked spells, equipment, quest progress, and settings.
- **Files Affected**: `lib/core/services/storage_service.dart`
- **Expected Outcome**: Permanent offline progress saving.

---

## Priority 1 (P1) — Core Gameplay Features & Progression

### P1-1: Flexible Spell & Element System
- **Problem**: No spell progression or elemental magic mechanics.
- **Why It Matters**: Core fantasy hooks require elemental strategy (Fire 🔥, Ice ❄️, Lightning ⚡, Nature 🍃, Arcane ✨, Dark 💀, Healing 💖).
- **Recommended Solution**: Build reusable `SpellModel` supporting damage, mana cost, cooldown, rarity (Common to Mythic), level upgrades, and animation/sound references.
- **Files Affected**: `lib/features/spells/`
- **Expected Outcome**: 10+ collectible & upgradable spells with elemental interaction.

### P1-2: Equipment & Stats System
- **Problem**: No character stats or gear customization.
- **Why It Matters**: RPG progression relies on acquiring better gear to defeat tougher enemies and bosses.
- **Recommended Solution**: Implement 6 equipment slots (Hat, Robe, Staff, Ring, Amulet, Boots) with stat bonuses (Magic Power, Defense, Crit Chance, Cooldown Reduction, Speed).
- **Files Affected**: `lib/features/inventory/`, `lib/features/equipment/`
- **Expected Outcome**: Full inventory & equipment paper-doll screen with side-by-side stat comparisons.

### P1-3: Multi-Mode Progression (Story Campaign, Endless Wave, Boss Arena)
- **Problem**: Only single round card game mode exists.
- **Why It Matters**: Player retention requires structured campaign progression + endless challenge modes.
- **Recommended Solution**: Create Story Mode (6 Chapters with 10+ levels each), Endless Horde Mode, and Boss Arena (Multi-phase boss fights).
- **Files Affected**: `lib/features/battle/`
- **Expected Outcome**: High replayability and structured goal-driven gameplay.

---

## Priority 2 (P2) — Visual Polish, Audio & Retention

### P2-1: Cinematic Dark Magical Design System
- **Problem**: Default dialog cards look generic.
- **Why It Matters**: Visual presentation dictates whether a mobile game feels premium or cheap.
- **Recommended Solution**: Implement glowing elemental borders, particle effects, custom fantasy typography (*Cinzel* + *Inter*), gold accents, and animated health/mana bars.
- **Files Affected**: `lib/core/theme/`
- **Expected Outcome**: Visual excellence matching top App Store / Play Store games.

### P2-2: Rewards, Quests, Daily Rewards & Achievements
- **Problem**: No meta-progression incentives.
- **Why It Matters**: Increases daily player retention and dopamine feedback loops.
- **Recommended Solution**: Implement 7-day Daily Login Rewards, Daily/Weekly Quests, and Achievement unlock milestones.
- **Files Affected**: `lib/features/quests/`, `lib/features/achievements/`
- **Expected Outcome**: Long-term player engagement.
