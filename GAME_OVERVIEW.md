# 🧙‍♂️ Wizard Card Game — Project Overview & Technical Report

An authoritative, cross-platform implementation of the classic **Wizard** card game built with **Flutter** (Frontend Client) and **Node.js** (Authoritative WebSocket Game Server).

---

## 1. Executive Summary

This project delivers a complete digital adaptation of the official Wizard card game supporting **3 to 8 players**. It features real-time online multiplayer, an offline practice mode against AI bots, realistic card rendering, authoritative server rule enforcement, and automated continuous delivery (CI/CD) of Android builds via GitHub Actions.

---

## 2. Technology Stack & Architecture

### Frontend (Client)
- **Framework**: Flutter 3 (Dart 3)
- **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod) (`StateNotifierProvider`, `StateProvider`)
- **Card UI Rendering**: [`playing_cards`](https://pub.dev/packages/playing_cards) package integrated with custom-crafted Wizard (`W`) and Jester (`N`) card-face widgets and custom-textured card backs.
- **Custom Components**:
  - `CardFanWidget`: Responsive horizontal overlapping card fan with legal-play highlighting and card selection animations.
  - `PokerTableWidget`: Felt-table representation showing player seats, dealer badges, turn indicators, active bids, trick tallies, and played trick cards positioned near each player's seat.
- **Typography & Styling**: Google Fonts (`Inter`), modern dark/slate theme with glassmorphic accents.

### Backend (Server)
- **Runtime**: Node.js (JavaScript, ES6+)
- **Networking**: `express` HTTP server + native `ws` (WebSockets)
- **Security & Scale**:
  - Sliding-window rate limiter (20 events/sec per client)
  - 8 KB `maxPayload` guard against socket flooding
  - Anti-cheat state masking: Opponent hands are masked (`type: 'HIDDEN'`) in network packets
  - $O(1)$ targeted room broadcasting: Lobby state updates are sent only to players browsing rooms
  - 25s ping-pong heartbeats to maintain connections across cloud edge proxies (Render, Heroku)
  - Automated 5-minute garbage collection for abandoned or finished games (30-minute TTL)
  - Health & observability endpoints: `/health` and `/stats`

### CI/CD & Distribution
- **GitHub Actions**: Automated workflow (`.github/workflows/build_apk.yml`) that compiles `flutter build apk --release` on every push to `main` and attaches the APK to GitHub Releases.

---

## 3. Official Game Rules & Logic Implementation

### 3.1. The 60-Card Deck
- **52 Standard Playing Cards**: 4 suits (Spades ♠, Hearts ♥, Diamonds ♦, Clubs ♣) with ranks 2 through 14 (Ace).
- **4 Wizard Cards (🧙‍♂️)**: Highest value in the game (`value: 99`). Trumps all standard cards, including trump Aces.
- **4 Jester Cards (🃏)**: Lowest value in the game (`value: 0`).
- Every physical card has a globally unique ID (e.g. `wizard_1`, `jester_3`, `card_14`) to preserve identity during dealing and shuffling.

### 3.2. Round Structure & Dealer Rotation
Total rounds are mathematically determined by player count:
$$\text{Total Rounds} = \lfloor 60 / N \rfloor$$

| Players | Rounds | Hand Sizes |
| :---: | :---: | :---: |
| **3** | 20 | Round 1 (1 card) → Round 20 (20 cards) |
| **4** | 15 | Round 1 (1 card) → Round 15 (15 cards) |
| **5** | 12 | Round 1 (1 card) → Round 12 (12 cards) |
| **6** | 10 | Round 1 (1 card) → Round 10 (10 cards) |
| **7** | 8  | Round 1 (1 card) → Round 8 (8 cards) |
| **8** | 7  | Round 1 (1 card) → Round 7 (7 cards) |

- **Dealer Rotation**: Rotates clockwise (+1 index modulo player count) after each round.
- **Turn Order**: Action always starts with the player to the dealer's left (`(dealerIndex + 1) % playerCount`).

### 3.3. Trump Selection
After hands are dealt, the top remaining deck card is revealed:
- **Standard Card Revealed**: The card's suit becomes the trump suit for the round.
- **Wizard Revealed**: The dealer chooses the trump suit before bidding begins.
- **Jester Revealed**: There is **no trump** for the round; suit rank alone dictates trick winners.
- **Final Round**: No cards remain undealt, so the final round is played with **no trump**.

### 3.4. Bidding Phase
- Players bid sequentially in clockwise turn order starting left of the dealer.
- Legal bids range from `0` to the current round number.
- Total bids do not have to equal the round number (overbidding and underbidding are legal).

### 3.5. Trick-Taking & Follow-Suit Rules
1. **Leading**: Player left of the dealer leads the first trick; winner of a trick leads the next.
2. **Follow Suit**:
   - If a normal suit card is led, players holding cards of that suit **must follow suit**.
   - **Wizards and Jesters can always be played legally**, even if the player holds the led suit.
   - If a Jester is led, the first standard suit card played thereafter sets the led suit.
   - If a Wizard is led, subsequent players may play any card freely.
3. **Winning the Trick**:
   - The **first Wizard** played always wins the trick.
   - If no Wizard is played, the **highest trump card** wins.
   - If no trump is played, the **highest card of the led suit** wins.
   - If all cards played in the trick are Jesters, the **first Jester played** wins.

### 3.6. Official Scoring
At the conclusion of each round, scores are updated:
- **Exact Bid Met**:
  $$\text{Score} = +20 + (10 \times \text{Tricks Won})$$
- **Missed Bid**:
  $$\text{Score} = -10 \times |\text{Bid} - \text{Tricks Won}|$$

---

## 4. Game Modes

### 4.1. Online Multiplayer
- **Lobby & Matchmaking**: Players can browse waiting rooms or create their own room (specifying 3–8 max players).
- **Room Codes**: Each room receives a clean 6-character Room Code (e.g., `WZ4821`).
- **Join by Room Code**: Players can tap **"Join with Code"**, type or paste the code, and enter directly.
- **Copy Code Feature**: One-tap clipboard copy button directly in the room lobby for easy sharing.
- **Authoritative Server**: Turn order, bidding validation, legal play checking, and trick resolution are verified server-side.

### 4.2. Offline Practice (Demo Mode)
- **Zero Network Requirement**: Runs 100% locally on the device; does not open sockets, ping servers, or require internet.
- **3 AI Bots**: Smart heuristic AI players that calculate risk-adjusted bids and play cards adhering strictly to follow-suit rules.
- **Instant Start**: Accessible directly with one tap from the main rooms screen.

---

## 5. Repository File Structure

```text
Wizard-Game/
├── .github/
│   └── workflows/
│       └── build_apk.yml           # Automated CI/CD workflow for release APK
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart     # Backend server URL and runtime environment
│   │   ├── demo/
│   │   │   └── demo_game_engine.dart # Local offline 4-player AI game engine
│   │   ├── mock/
│   │   │   └── demo_game_data.dart # Sample data for testing
│   │   └── network/
│   │       ├── local_game_server.dart # Embedded local LAN server fallback
│   │       └── socket_service.dart # WebSocket connection & event emitter
│   ├── models/
│   │   ├── game_card.dart          # 60-card deck model & suit enums
│   │   ├── game_room.dart          # Room configuration & state model
│   │   ├── game_state.dart         # Turn index, phase, scores, trick cards
│   │   └── player.dart             # Player data model (bid, tricks, score)
│   ├── providers/
│   │   ├── game_provider.dart      # Active gameplay Riverpod state notifier
│   │   ├── player_provider.dart    # Local player profile notifier
│   │   └── room_provider.dart      # Room list and current room notifier
│   ├── screens/
│   │   ├── create_room/            # Room creation screen
│   │   ├── game/                   # Main game screen (Poker table, fan, score sheet)
│   │   ├── lobby/                  # Room lobby screen (Player slots, Room Code)
│   │   ├── name/                   # Welcome player name entry screen
│   │   └── server_list/            # Public room browser & Join by Code dialog
│   └── widgets/
│       ├── card_fan_widget.dart    # Horizontal overlapping player hand
│       ├── game_card_widget.dart   # Visual card widget (Custom W & N artwork)
│       ├── player_tile.dart        # Lobby player slot tile
│       ├── poker_table_widget.dart # Central felt poker table & trick cards
│       ├── result_dialog.dart      # Round score summary dialog
│       └── room_tile.dart          # Public room card in browser
├── server/
│   ├── package.json
│   └── server.js                   # Node.js authoritative WebSocket game server
├── test/
│   └── card_ui_test.dart           # 20 automated unit & regression tests
└── pubspec.yaml                    # Flutter dependencies & metadata
```

---

## 6. Automated Test Suite (20 Tests)

All critical game mechanics and UI components are covered by unit and widget tests:

| Test ID | Category | Description | Status |
| :--- | :--- | :--- | :---: |
| **1** | Deck | Exact 60-card deck with unique IDs | Passed |
| **2** | Deck | 52 standard cards correctly mapped to `playing_cards` | Passed |
| **3** | Deck | Legal follow-suit card validation | Passed |
| **4** | UI Widget | WizardCardWidget renders custom 'W' & wizard artwork | Passed |
| **5** | UI Widget | JesterCardWidget renders custom 'N' & jester artwork | Passed |
| **6** | UI Widget | CardBackWidget renders textured geometric back | Passed |
| **7** | UI Widget | GameCardWidget renders standard cards | Passed |
| **8** | UI Widget | CardFanWidget renders overlapping fan and handles taps | Passed |
| **9** | UI Widget | PokerTableWidget renders seats and trick card positions | Passed |
| **10** | Offline | Demo mode initializes without network/sockets | Passed |
| **RT-1** | Regression | Round 1 deals exactly 1 card per player | Passed |
| **RT-2** | Regression | Total rounds table conforms to official rules (3-8 players) | Passed |
| **RT-3** | Regression | Exact bid scores $+20 + 10 \times \text{tricks}$ | Passed |
| **RT-4** | Regression | Overbid penalty scores $-10 \times \|\text{diff}\|$ | Passed |
| **RT-5** | Regression | Underbid penalty scores $-10 \times \|\text{diff}\|$ | Passed |
| **RT-6** | Regression | First Wizard played wins trick over trump Ace | Passed |
| **RT-7** | Regression | Lowest trump beats highest card of led suit | Passed |
| **RT-8** | Regression | All-Jester trick won by first Jester played | Passed |
| **RT-9** | Regression | Strict follow-suit enforcement when led suit is held | Passed |
| **RT-10**| Regression | Bid range strictly bounded between $0$ and current round | Passed |

---

## 7. How to Run Locally

### Run Backend Server
```powershell
cd d:\Work\Wizard\server
node server.js
```
*Server runs on port 3000 (configurable via `PORT` environment variable).*

### Run Flutter Client
```powershell
cd d:\Work\Wizard
flutter run -d chrome    # For Web
flutter run -d edge      # For Windows
flutter run              # For connected Android/iOS device
```

### Run Tests & Lints
```powershell
flutter analyze
flutter test
```

---

## 8. Deployment & Release

- **Android Release**: Available on [GitHub Releases](https://github.com/amaljithmk07/Wizard-Game/releases).
- **Backend Deployment**: Hosted on [Render](https://render.com) at `wss://wizard-game-sk6k.onrender.com`.
- **CI/CD Pipeline**: Every `git push origin main` triggers the GitHub Action to compile and publish the latest `Wizard-Game.apk`.
