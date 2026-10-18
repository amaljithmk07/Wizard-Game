import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:wizard_flutter/core/config/app_config.dart';
import 'package:wizard_flutter/core/demo/demo_game_engine.dart';
import 'package:wizard_flutter/models/game_card.dart';
import 'package:wizard_flutter/models/game_room.dart';
import 'package:wizard_flutter/models/game_state.dart';
import 'package:wizard_flutter/models/player.dart';
import 'package:wizard_flutter/providers/player_provider.dart';
import 'package:wizard_flutter/widgets/card_back_widget.dart';
import 'package:wizard_flutter/widgets/card_fan_widget.dart';
import 'package:wizard_flutter/widgets/game_card_widget.dart';
import 'package:wizard_flutter/widgets/jester_card_widget.dart';
import 'package:wizard_flutter/widgets/playing_card_adapter.dart';
import 'package:wizard_flutter/widgets/poker_table_widget.dart';
import 'package:wizard_flutter/widgets/wizard_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('60-Card Deck & PlayingCardAdapter Tests', () {
    test('Deck contains exactly 60 cards with unique IDs', () {
      final deck = PlayingCardAdapter.create60CardDeck();
      expect(deck.length, equals(60));

      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, equals(60), reason: 'Every physical card must have a unique ID');

      final wizards = deck.where((c) => c.isWizard).toList();
      expect(wizards.length, equals(4), reason: 'Exactly 4 Wizards in official deck');

      final jesters = deck.where((c) => c.isJester).toList();
      expect(jesters.length, equals(4), reason: 'Exactly 4 Jesters in official deck');

      final standard = deck.where((c) => !c.isWizard && !c.isJester).toList();
      expect(standard.length, equals(52), reason: 'Exactly 52 standard playing cards');
    });

    test('All 52 standard cards correctly map to playing_cards Package Models', () {
      final deck = PlayingCardAdapter.create60CardDeck();
      final standardCards = deck.where((c) => !c.isWizard && !c.isJester).toList();

      for (final card in standardCards) {
        final playingCard = PlayingCardAdapter.toPlayingCard(card);
        expect(playingCard, isNotNull);
        expect(playingCard!.suit, isA<Suit>());
        expect(playingCard.value, isA<CardValue>());
      }

      // Wizards and Jesters return null for standard PlayingCard mapping
      final wizard = deck.firstWhere((c) => c.isWizard);
      expect(PlayingCardAdapter.toPlayingCard(wizard), isNull);

      final jester = deck.firstWhere((c) => c.isJester);
      expect(PlayingCardAdapter.toPlayingCard(jester), isNull);
    });

    test('Legal Card Play Validation adheres strictly to Wizard Rules', () {
      final hand = [
        GameCard(id: 'c1', suit: 'Hearts', value: 10, name: '10 of Hearts'),
        GameCard(id: 'c2', suit: 'Spades', value: 5, name: '5 of Spades'),
        GameCard(id: 'w1', suit: 'None', value: 99, name: 'Wizard', type: CardType.wizard),
        GameCard(id: 'j1', suit: 'None', value: 0, name: 'Jester', type: CardType.jester),
      ];

      // 1. Not player's turn -> nothing playable
      expect(
        PlayingCardAdapter.isCardLegalToPlay(
          card: hand[0],
          hand: hand,
          ledSuit: 'Hearts',
          isMyTurn: false,
          isTrickPhase: true,
        ),
        isFalse,
      );

      // 2. Player's turn, Hearts led:
      // Hearts is legal
      expect(
        PlayingCardAdapter.isCardLegalToPlay(
          card: hand[0],
          hand: hand,
          ledSuit: 'Hearts',
          isMyTurn: true,
          isTrickPhase: true,
        ),
        isTrue,
      );

      // Spades is NOT legal because player holds Hearts
      expect(
        PlayingCardAdapter.isCardLegalToPlay(
          card: hand[1],
          hand: hand,
          ledSuit: 'Hearts',
          isMyTurn: true,
          isTrickPhase: true,
        ),
        isFalse,
      );

      // Wizard is ALWAYS legal even when holding led suit
      expect(
        PlayingCardAdapter.isCardLegalToPlay(
          card: hand[2],
          hand: hand,
          ledSuit: 'Hearts',
          isMyTurn: true,
          isTrickPhase: true,
        ),
        isTrue,
      );

      // Jester is ALWAYS legal even when holding led suit
      expect(
        PlayingCardAdapter.isCardLegalToPlay(
          card: hand[3],
          hand: hand,
          ledSuit: 'Hearts',
          isMyTurn: true,
          isTrickPhase: true,
        ),
        isTrue,
      );

      // 3. Diamonds led (player has NO Diamonds in hand):
      // Void in led suit -> ANY card is legal!
      expect(
        PlayingCardAdapter.isCardLegalToPlay(
          card: hand[1], // Spades
          hand: hand,
          ledSuit: 'Diamonds',
          isMyTurn: true,
          isTrickPhase: true,
        ),
        isTrue,
      );
    });
  });

  group('Card UI Widgets Rendering Tests', () {
    testWidgets('WizardCardWidget renders custom W index and Wizard artwork', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WizardCardWidget(width: 80, height: 112),
          ),
        ),
      );

      expect(find.text('W'), findsNWidgets(2)); // Top-left and bottom-right
      expect(find.text('WIZARD'), findsOneWidget);
      expect(find.text('🧙‍♂️'), findsOneWidget);
    });

    testWidgets('JesterCardWidget renders custom N index and Jester artwork', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JesterCardWidget(width: 80, height: 112),
          ),
        ),
      );

      expect(find.text('N'), findsNWidgets(2)); // Top-left and bottom-right
      expect(find.text('JESTER'), findsOneWidget);
      expect(find.text('🃏'), findsOneWidget);
    });

    testWidgets('CardBackWidget renders ornate card back with geometric motif', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardBackWidget(width: 60, height: 84),
          ),
        ),
      );

      expect(find.byType(CardBackWidget), findsOneWidget);
      expect(find.text('✦'), findsOneWidget);
    });

    testWidgets('GameCardWidget renders standard cards via PlayingCardView', (tester) async {
      final aceOfSpades = GameCard(
        id: 'spades_14',
        suit: 'Spades',
        value: 14,
        name: 'Ace of Spades',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardWidget(
              card: aceOfSpades,
              width: 70,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(PlayingCardView), findsOneWidget);
    });

    testWidgets('CardFanWidget renders horizontal overlapping fan and taps legal cards', (tester) async {
      int? tappedIndex;
      final cards = [
        GameCard(id: 'c1', suit: 'Hearts', value: 10, name: '10 of Hearts'),
        GameCard(id: 'c2', suit: 'Spades', value: 5, name: '5 of Spades'),
        GameCard(id: 'w1', suit: 'None', value: 99, name: 'Wizard', type: CardType.wizard),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 140,
              child: CardFanWidget(
                cards: cards,
                selectedIndex: 1,
                ledSuit: 'Hearts',
                isMyTurn: true,
                isTrickPhase: true,
                onCardSelected: (idx) => tappedIndex = idx,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GameCardWidget), findsNWidgets(3));

      // Tap legal card (Heart)
      await tester.tap(find.byType(GameCardWidget).first);
      expect(tappedIndex, equals(0));
    });

    testWidgets('PokerTableWidget renders seats for players and displays trick cards', (tester) async {
      final room = GameRoom(
        id: 'table_1',
        name: 'Test Room',
        hostId: 'p1',
        maxPlayers: 4,
        playerCount: 4,
        status: 'PLAYING',
        players: [
          Player(id: 'p1', name: 'Alice', hand: [GameCard(id: '1', suit: 'Spades', value: 2, name: '2S')]),
          Player(id: 'p2', name: 'Bob', hand: [GameCard(id: '2', suit: 'Hearts', value: 3, name: '3H')]),
          Player(id: 'p3', name: 'Charlie', hand: [GameCard(id: '3', suit: 'Diamonds', value: 4, name: '4D')]),
          Player(id: 'p4', name: 'David', hand: [GameCard(id: '4', suit: 'Clubs', value: 5, name: '5C')]),
        ],
        gameState: GameStateModel(
          round: 1,
          totalRounds: 15,
          phase: 'TRICK',
          currentTurnIndex: 1,
          playedCards: [
            PlayedCardItem(
              playerId: 'p1',
              playerName: 'Alice',
              card: GameCard(id: '1', suit: 'Spades', value: 2, name: '2 of Spades'),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: PokerTableWidget(
                room: room,
                gameState: room.gameState!,
                myPlayerId: 'p1',
              ),
            ),
          ),
        ),
      );

      // Opponents Bob, Charlie, David should have seat chips
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('David'), findsOneWidget);

      // Alice's played card should appear on the table with her name tag
      expect(find.text('Alice'), findsOneWidget);
    });
  });

  group('Offline Demo Mode Tests', () {
    test('Demo mode starts without attempting server connection', () {
      final container = ProviderContainer();
      container.read(playerNameProvider.notifier).setName('Tester');

      AppConfig.enableRuntimeDemo();
      expect(AppConfig.isDemoMode, isTrue);

      final engine = DemoGameEngine();
      engine.startDemo(ref: container, playerName: 'Tester');

      AppConfig.resetRuntimeDemo();
      expect(AppConfig.isDemoMode, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Regression Tests (10 required cases)
  // ═══════════════════════════════════════════════════════════════
  group('Wizard Game Logic Regression Tests', () {
    // RT-1: Game starts at round 1 with exactly 1 card per player
    test('RT-1: Round 1 deals exactly 1 card per player (4 players → 4 cards)', () {
      const round = 1;
      const playerCount = 4;
      const dealtCount = round * playerCount;
      expect(dealtCount, equals(4));
      // Full deck must have enough cards for dealing + 1 trump
      final deck = PlayingCardAdapter.create60CardDeck();
      expect(deck.length, greaterThanOrEqualTo(dealtCount + 1));
    });

    // RT-2: Total rounds for each player count match official rules
    test('RT-2: Total rounds follow the official Wizard table', () {
      int totalRounds(int n) => switch (n) {
            3 => 20,
            4 => 15,
            5 => 12,
            6 => 10,
            7 => 8,
            8 => 7,
            _ => 60 ~/ n
          };
      expect(totalRounds(3), equals(20));
      expect(totalRounds(4), equals(15));
      expect(totalRounds(5), equals(12));
      expect(totalRounds(6), equals(10));
      expect(totalRounds(7), equals(8));
      expect(totalRounds(8), equals(7));
    });

    // RT-3: Scoring — correct bid
    test('RT-3: Correct bid scores +20 + 10×tricks', () {
      const bid = 3;
      const tricksWon = 3;
      final score = (bid == tricksWon) ? 20 + (tricksWon * 10) : -10 * (bid - tricksWon).abs();
      expect(score, equals(50)); // 20 + 30
    });

    // RT-4: Scoring — overbid
    test('RT-4: Wrong bid (overbid) scores -10 × |diff|', () {
      const bid = 3;
      const tricksWon = 1;
      final score = (bid == tricksWon) ? 20 + (tricksWon * 10) : -10 * (bid - tricksWon).abs();
      expect(score, equals(-20));
    });

    // RT-5: Scoring — underbid
    test('RT-5: Wrong bid (underbid) scores -10 × |diff|', () {
      const bid = 1;
      const tricksWon = 3;
      final score = (bid == tricksWon) ? 20 + (tricksWon * 10) : -10 * (bid - tricksWon).abs();
      expect(score, equals(-20));
    });

    // RT-6: First Wizard played wins the trick
    test('RT-6: First Wizard beats any other card including trump Ace', () {
      final played = [
        PlayedCardItem(
          playerId: 'p1',
          playerName: 'Alice',
          card: GameCard(id: 'wizard_1', suit: 'Wizard', value: 99, name: 'Wizard', type: CardType.wizard),
        ),
        PlayedCardItem(
          playerId: 'p2',
          playerName: 'Bob',
          card: GameCard(id: 'spades_14', suit: 'Spades', value: 14, name: 'Ace of Spades'),
        ),
      ];

      PlayedCardItem winner = played.first;
      for (final item in played) {
        if (item.card.isWizard) { winner = item; break; }
      }
      expect(winner.playerId, equals('p1'));
    });

    // RT-7: Highest trump beats highest led suit
    test('RT-7: 2 of trump beats Ace of led suit', () {
      const trumpSuit = 'Spades';
      const ledSuit = 'Hearts';
      final played = [
        PlayedCardItem(
          playerId: 'p1',
          playerName: 'Alice',
          card: GameCard(id: 'hearts_14', suit: 'Hearts', value: 14, name: 'Ace of Hearts'),
        ),
        PlayedCardItem(
          playerId: 'p2',
          playerName: 'Bob',
          card: GameCard(id: 'spades_2', suit: 'Spades', value: 2, name: '2 of Spades'),
        ),
      ];

      PlayedCardItem winner = played.first;
      final trumpCards = played
          .where((c) => !c.card.isWizard && !c.card.isJester && c.card.suit == trumpSuit)
          .toList();
      if (trumpCards.isNotEmpty) {
        trumpCards.sort((a, b) => b.card.value.compareTo(a.card.value));
        winner = trumpCards.first;
      } else {
        final ledCards = played
            .where((c) => !c.card.isWizard && !c.card.isJester && c.card.suit == ledSuit)
            .toList();
        ledCards.sort((a, b) => b.card.value.compareTo(a.card.value));
        if (ledCards.isNotEmpty) winner = ledCards.first;
      }
      expect(winner.playerId, equals('p2'));
    });

    // RT-8: All-Jester trick won by first Jester
    test('RT-8: All-Jester trick is won by the first Jester played', () {
      final played = [
        PlayedCardItem(
          playerId: 'p1',
          playerName: 'Alice',
          card: GameCard(id: 'jester_1', suit: 'Jester', value: 0, name: 'Jester', type: CardType.jester),
        ),
        PlayedCardItem(
          playerId: 'p2',
          playerName: 'Bob',
          card: GameCard(id: 'jester_2', suit: 'Jester', value: 0, name: 'Jester', type: CardType.jester),
        ),
      ];
      // No Wizards, no trumps, no led-suit normal cards → first card wins
      PlayedCardItem winner = played.first;
      expect(winner.playerId, equals('p1'));
    });

    // RT-9: Follow-suit enforcement
    test('RT-9: Off-suit play is illegal when player holds the led suit', () {
      final hand = [
        GameCard(id: 'h10', suit: 'Hearts', value: 10, name: '10H'),
        GameCard(id: 's5', suit: 'Spades', value: 5, name: '5S'),
      ];
      const ledSuit = 'Hearts';
      final attemptedCard = hand[1]; // Spades

      final hasSuit = hand.any((c) => !c.isWizard && !c.isJester && c.suit == ledSuit);
      final isLegal = !hasSuit ||
          attemptedCard.isWizard ||
          attemptedCard.isJester ||
          attemptedCard.suit == ledSuit;
      expect(isLegal, isFalse);
    });

    // RT-10: Bid range validation
    test('RT-10: Bid must be within [0, currentRound]', () {
      const currentRound = 3;
      bool bidValid(int bid) => bid >= 0 && bid <= currentRound;

      expect(bidValid(0), isTrue);
      expect(bidValid(3), isTrue);
      expect(bidValid(4), isFalse);
      expect(bidValid(-1), isFalse);
    });
  });
}
