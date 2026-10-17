import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizard_flutter/models/game_card.dart';
import 'package:wizard_flutter/models/game_room.dart';
import 'package:wizard_flutter/models/game_state.dart';
import 'package:wizard_flutter/models/player.dart';

void main() {
  group('GameCard', () {
    test('fromJson parses a standard numbered card', () {
      final card = GameCard.fromJson({
        'id': 'card_1',
        'suit': 'Hearts',
        'value': 10,
        'name': '10 ♥',
      });
      expect(card.id, 'card_1');
      expect(card.suit, 'Hearts');
      expect(card.value, 10);
      expect(card.displayValue, '10');
      expect(card.suitSymbol, '♥');
    });

    test('fromJson parses face cards correctly', () {
      final king = GameCard.fromJson(
          {'id': 'k', 'suit': 'Spades', 'value': 13, 'name': 'K'});
      final queen = GameCard.fromJson(
          {'id': 'q', 'suit': 'Diamonds', 'value': 12, 'name': 'Q'});
      final jack = GameCard.fromJson(
          {'id': 'j', 'suit': 'Clubs', 'value': 11, 'name': 'J'});
      final ace = GameCard.fromJson(
          {'id': 'a', 'suit': 'Hearts', 'value': 14, 'name': 'A'});

      expect(king.displayValue, 'K');
      expect(queen.displayValue, 'Q');
      expect(jack.displayValue, 'J');
      expect(ace.displayValue, 'A');
    });

    test('suitSymbol returns correct unicode for each suit', () {
      final hearts = GameCard.fromJson(
          {'id': 'h', 'suit': 'hearts', 'value': 5, 'name': '5'});
      final diamonds = GameCard.fromJson(
          {'id': 'd', 'suit': 'diamonds', 'value': 5, 'name': '5'});
      final clubs = GameCard.fromJson(
          {'id': 'c', 'suit': 'clubs', 'value': 5, 'name': '5'});
      final spades = GameCard.fromJson(
          {'id': 's', 'suit': 'spades', 'value': 5, 'name': '5'});

      expect(hearts.suitSymbol, '♥');
      expect(diamonds.suitSymbol, '♦');
      expect(clubs.suitSymbol, '♣');
      expect(spades.suitSymbol, '♠');
    });

    test('suitColor is red for Hearts and Diamonds', () {
      final hearts = GameCard.fromJson(
          {'id': 'h', 'suit': 'Hearts', 'value': 5, 'name': '5'});
      final diamonds = GameCard.fromJson(
          {'id': 'd', 'suit': 'Diamonds', 'value': 5, 'name': '5'});
      final spades = GameCard.fromJson(
          {'id': 's', 'suit': 'Spades', 'value': 5, 'name': '5'});
      final clubs = GameCard.fromJson(
          {'id': 'c', 'suit': 'Clubs', 'value': 5, 'name': '5'});

      expect(hearts.suitColor, const Color(0xFFDC2626));
      expect(diamonds.suitColor, const Color(0xFFDC2626));
      expect(spades.suitColor, const Color(0xFF1E293B));
      expect(clubs.suitColor, const Color(0xFF1E293B));
    });

    test('fromJson with missing fields applies defaults', () {
      final card = GameCard.fromJson({});
      expect(card.id, '');
      expect(card.suit, 'Spades');
      expect(card.value, 2);
      expect(card.name, '');
    });

    test('toJson then fromJson round-trips correctly', () {
      final original = GameCard.fromJson({
        'id': 'card_42',
        'suit': 'Clubs',
        'value': 7,
        'name': '7 ♣',
      });
      final json = original.toJson();
      final roundTripped = GameCard.fromJson(json);

      expect(roundTripped.id, original.id);
      expect(roundTripped.suit, original.suit);
      expect(roundTripped.value, original.value);
      expect(roundTripped.name, original.name);
    });
  });

  group('Player', () {
    test('fromJson parses all fields', () {
      final player = Player.fromJson({
        'id': 'socket_abc',
        'name': 'Alice',
        'score': 30,
        'isHost': true,
        'hand': [],
      });
      expect(player.id, 'socket_abc');
      expect(player.name, 'Alice');
      expect(player.score, 30);
      expect(player.isHost, true);
      expect(player.hand, isEmpty);
    });

    test('fromJson with hand containing cards', () {
      final player = Player.fromJson({
        'id': 'p1',
        'name': 'Bob',
        'score': 0,
        'isHost': false,
        'hand': [
          {'id': 'c1', 'suit': 'Spades', 'value': 10, 'name': '10 ♠'},
          {'id': 'c2', 'suit': 'Hearts', 'value': 7, 'name': '7 ♥'},
        ],
      });
      expect(player.hand.length, 2);
      expect(player.hand[0].suit, 'Spades');
      expect(player.hand[1].suit, 'Hearts');
    });

    test('fromJson defaults to score=0, isHost=false, empty hand', () {
      final player = Player.fromJson({'id': 'x', 'name': 'Player'});
      expect(player.score, 0);
      expect(player.isHost, false);
      expect(player.hand, isEmpty);
    });

    test('toJson round-trips name and score', () {
      final player = Player.fromJson({
        'id': 'p',
        'name': 'Eve',
        'score': 20,
        'isHost': false,
        'hand': [],
      });
      final json = player.toJson();
      expect(json['name'], 'Eve');
      expect(json['score'], 20);
    });
  });

  group('GameStateModel', () {
    test('fromJson parses currentTurnIndex and winner', () {
      final state = GameStateModel.fromJson({
        'currentTurnIndex': 2,
        'playedCards': [],
        'winner': null,
      });
      expect(state.currentTurnIndex, 2);
      expect(state.playedCards, isEmpty);
      expect(state.winner, isNull);
    });

    test('fromJson parses played cards with nested card data', () {
      final state = GameStateModel.fromJson({
        'currentTurnIndex': 0,
        'playedCards': [
          {
            'playerId': 'p1',
            'playerName': 'Alice',
            'card': {'id': 'c1', 'suit': 'Hearts', 'value': 10, 'name': '10 ♥'},
          },
        ],
        'winner': 'Alice',
      });
      expect(state.playedCards.length, 1);
      expect(state.playedCards.first.playerId, 'p1');
      expect(state.playedCards.first.playerName, 'Alice');
      expect(state.playedCards.first.card.suit, 'Hearts');
      expect(state.playedCards.first.card.value, 10);
      expect(state.winner, 'Alice');
    });

    test('fromJson with no playedCards key defaults to empty list', () {
      final state = GameStateModel.fromJson({'currentTurnIndex': 1});
      expect(state.playedCards, isEmpty);
      expect(state.currentTurnIndex, 1);
    });
  });

  group('GameRoom', () {
    test('fromJson parses a waiting room', () {
      final room = GameRoom.fromJson({
        'id': 'room_123',
        'name': "Alice's Room",
        'hostId': 'socket_abc',
        'maxPlayers': 4,
        'playerCount': 1,
        'status': 'WAITING',
        'players': [
          {
            'id': 'socket_abc',
            'name': 'Alice',
            'score': 0,
            'isHost': true,
            'hand': []
          },
        ],
        'gameState': null,
      });
      expect(room.id, 'room_123');
      expect(room.name, "Alice's Room");
      expect(room.isWaiting, true);
      expect(room.isFull, false);
      expect(room.players.length, 1);
      expect(room.gameState, isNull);
    });

    test('isFull true when playerCount >= maxPlayers', () {
      final room = GameRoom.fromJson({
        'id': 'r',
        'name': 'Full Room',
        'hostId': 'h',
        'maxPlayers': 2,
        'playerCount': 2,
        'status': 'WAITING',
        'players': [],
      });
      expect(room.isFull, true);
    });

    test('isWaiting false when status is PLAYING', () {
      final room = GameRoom.fromJson({
        'id': 'r',
        'name': 'Playing Room',
        'hostId': 'h',
        'maxPlayers': 4,
        'playerCount': 2,
        'status': 'PLAYING',
        'players': [],
      });
      expect(room.isWaiting, false);
    });

    test('fromJson parses embedded gameState', () {
      final room = GameRoom.fromJson({
        'id': 'r',
        'name': 'Room',
        'hostId': 'h',
        'maxPlayers': 2,
        'playerCount': 2,
        'status': 'PLAYING',
        'players': [],
        'gameState': {
          'currentTurnIndex': 1,
          'playedCards': [],
          'winner': null,
        },
      });
      expect(room.gameState, isNotNull);
      expect(room.gameState!.currentTurnIndex, 1);
    });

    test('playerCount defaults to players list length when not provided', () {
      final room = GameRoom.fromJson({
        'id': 'r',
        'name': 'Room',
        'hostId': 'h',
        'maxPlayers': 4,
        'status': 'WAITING',
        'players': [
          {'id': 'a', 'name': 'A', 'score': 0, 'isHost': true, 'hand': []},
          {'id': 'b', 'name': 'B', 'score': 0, 'isHost': false, 'hand': []},
        ],
      });
      expect(room.playerCount, 2);
    });
  });

  group('Wizard Rules & Scoring Logic', () {
    test('Wizard and Jester cards identify correctly and render special values', () {
      final wizard = GameCard.fromJson({
        'id': 'w1',
        'name': 'Wizard 🧙‍♂️',
        'type': 'WIZARD',
        'suit': 'Wizard',
        'value': 99,
      });
      final jester = GameCard.fromJson({
        'id': 'j1',
        'name': 'Jester 🃏',
        'type': 'JESTER',
        'suit': 'Jester',
        'value': 0,
      });

      expect(wizard.isWizard, isTrue);
      expect(wizard.isJester, isFalse);
      expect(wizard.displayValue, 'W');
      expect(wizard.suitSymbol, '🧙‍♂️');

      expect(jester.isJester, isTrue);
      expect(jester.isWizard, isFalse);
      expect(jester.displayValue, 'N');
      expect(jester.suitSymbol, '🃏');
    });

    test('Rule 6: Scoring calculates +20 plus +10 per trick on correct bid', () {
      int calculateScore(int bid, int tricksWon) {
        if (bid == tricksWon) {
          return 20 + (tricksWon * 10);
        } else {
          return -10 * (tricksWon - bid).abs();
        }
      }

      // Bid 3, won 3 -> 20 + 30 = 50
      expect(calculateScore(3, 3), 50);

      // Bid 0, won 0 -> 20 + 0 = 20
      expect(calculateScore(0, 0), 20);

      // Bid 3, won 1 -> -10 * 2 = -20
      expect(calculateScore(3, 1), -20);

      // Bid 1, won 3 -> -10 * 2 = -20
      expect(calculateScore(1, 3), -20);

      // Bid 2, won 0 -> -10 * 2 = -20
      expect(calculateScore(2, 0), -20);
    });
  });
}
