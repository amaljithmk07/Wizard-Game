# 🧙‍♂️ Wizard Card Game

[![Build & Release Android APK](https://github.com/amaljithmk07/Wizard-Game/actions/workflows/build_apk.yml/badge.svg)](https://github.com/amaljithmk07/Wizard-Game/actions/workflows/build_apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/amaljithmk07/Wizard-Game?label=Download%20APK&color=2563EB)](https://github.com/amaljithmk07/Wizard-Game/releases)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter)](https://flutter.dev)

A modern, cross-platform multiplayer implementation of the classic **Wizard** card game built with **Flutter** and **Node.js WebSockets**.

Supports **3 to 8 players** online with custom Room Codes, plus an instant **Offline Practice Mode** against AI bots.

---

## 📱 Download & Play

- **Android**: Download the latest release from the [Releases Page](https://github.com/amaljithmk07/Wizard-Game/releases) (`Wizard-Game.apk`).
- **Web / Desktop**: Run locally using Flutter (`flutter run -d chrome`).

---

## ✨ Key Features

- **Real-Time Online Multiplayer**: Supports 3–8 players per game room with authoritative server-side rule verification.
- **Easy Room Joining**: Share and join rooms instantly with 6-character **Room Codes** (e.g. `WZ4821`).
- **Offline Practice Mode**: Zero-network local demo against 3 AI bots.
- **Official 60-Card Wizard Deck**: 52 standard cards + 4 Wizards (`W`) + 4 Jesters (`N`) with unique IDs and custom artwork.
- **Authentic Card UI**:
  - `CardFanWidget`: Responsive overlapping card fan for the player's hand.
  - `PokerTableWidget`: Felt poker table with trick placements, player seats, turn halos, and dealer indicators.
- **Official Rule Enforcement**:
  - Accurate round counts (e.g. 15 rounds for 4 players, 20 for 3).
  - Proper dealer rotation and sequential bidding.
  - Follow-suit validation (Wizards/Jesters playable anytime; first Wizard wins).
  - Official scoring ($+20 + 10\times\text{tricks}$ for exact bids; $-10\times\text{diff}$ for misses).
- **Automated CI/CD**: Automatic Android APK compilation on every push via GitHub Actions.

---

## 📖 Complete Documentation

For the full architectural report, rule breakdown, test matrix, and server configuration:
👉 **[Read the Full GAME_OVERVIEW.md](GAME_OVERVIEW.md)**

---

## 🚀 Quick Start (Local Development)

### 1. Start Server
```powershell
cd server
npm install
node server.js
```

### 2. Run Flutter Client
```powershell
flutter pub get
flutter run
```

### 3. Run Automated Tests
```powershell
flutter analyze
flutter test
```

---

## 📄 License
This project is open source and available under the MIT License.
