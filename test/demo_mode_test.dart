import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizard_flutter/core/config/app_config.dart';
import 'package:wizard_flutter/core/mock/demo_game_data.dart';
import 'package:wizard_flutter/core/network/socket_service.dart';
import 'package:wizard_flutter/providers/game_provider.dart';
import 'package:wizard_flutter/providers/player_provider.dart';
import 'package:wizard_flutter/providers/room_provider.dart';
import 'package:wizard_flutter/screens/name/name_screen.dart';
import 'package:wizard_flutter/screens/server_list/server_list_screen.dart';
import 'package:wizard_flutter/screens/lobby/room_lobby_screen.dart';
import 'package:wizard_flutter/screens/result/game_result_screen.dart';
import 'package:wizard_flutter/screens/create_room/create_room_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'player_name': 'Tester'});
    AppConfig.enableRuntimeDemo();
  });

  tearDown(() {
    AppConfig.resetRuntimeDemo();
    SocketService().disconnect();
  });

  group('Demo Mode Configuration & Guards', () {
    test('demoMode constant exists and is accessible', () {
      expect(demoMode, isA<bool>());
    });

    test('SocketService does not connect or emit in Demo Mode', () {
      final socketService = SocketService();
      socketService.connect(serverUrl: 'http://localhost:3000');

      expect(socketService.isConnected, isFalse);
      expect(socketService.socketId, 'demo_player_local');

      // Calling emit or on in demo mode does not throw
      socketService.emit('test_event', {'data': 123});
      socketService.on('test_event', (_) {});
      socketService.off('test_event');
    });

    test('getInitialDemoRooms returns populated valid rooms', () {
      final rooms = getInitialDemoRooms();
      expect(rooms.isNotEmpty, isTrue);
      expect(rooms.length, greaterThanOrEqualTo(2));
      for (final r in rooms) {
        expect(r.id.isNotEmpty, isTrue);
        expect(r.name.isNotEmpty, isTrue);
        expect(r.players.isNotEmpty, isTrue);
      }
    });

    test('generateDemoDeck creates 52 distinct playing cards', () {
      final deck = generateDemoDeck();
      expect(deck.length, 52);
      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, 52);
    });
  });

  group('Demo Mode Providers & Flow', () {
    test('RoomsNotifier fetches demo rooms when demo mode is active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomsProvider.notifier);
      notifier.fetchRooms();

      final rooms = container.read(roomsProvider);
      expect(rooms.isNotEmpty, isTrue);
      expect(rooms.any((r) => r.id == 'demo_room_dragon'), isTrue);
    });

    test(
        'CurrentRoomNotifier creates demo room and populates currentRoomProvider',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(playerNameProvider.notifier).setName('Tester');
      container
          .read(currentRoomProvider.notifier)
          .createRoom('My Demo Room', 4);

      final currentRoom = container.read(currentRoomProvider);
      expect(currentRoom, isNotNull);
      expect(currentRoom!.name, 'My Demo Room');
      expect(currentRoom.players.any((p) => p.name == 'Tester'), isTrue);
      expect(currentRoom.playerCount, greaterThanOrEqualTo(2));
    });

    test('CurrentRoomNotifier joins demo room without null spinner', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(roomsProvider.notifier).fetchRooms();
      container.read(playerNameProvider.notifier).setName('Hero');
      container.read(currentRoomProvider.notifier).joinRoom('demo_room_dragon');

      final currentRoom = container.read(currentRoomProvider);
      expect(currentRoom, isNotNull);
      expect(currentRoom!.id, 'demo_room_dragon');
      expect(currentRoom.players.any((p) => p.name == 'Hero'), isTrue);
    });

    test('Starting demo game deals hands and transitions status to PLAYING',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(currentRoomProvider.notifier)
          .createRoom('Combat Chamber', 4);
      container.read(currentRoomProvider.notifier).startGame();

      final currentRoom = container.read(currentRoomProvider);
      expect(currentRoom!.status, 'PLAYING');
      expect(currentRoom.players.first.hand.length, 5);
      expect(currentRoom.gameState, isNotNull);
    });

    testWidgets('GameNotifier demo simulation handles card play and scoring',
        (tester) async {
      final container = ProviderContainer();

      container.read(playerNameProvider.notifier).setName('CardPlayer');
      container.read(currentRoomProvider.notifier).createRoom('Play Room', 2);
      container.read(currentRoomProvider.notifier).startGame();

      final room = container.read(currentRoomProvider)!;
      final gameNotifier = container.read(gameProvider.notifier);
      gameNotifier.initDemoGame(room);

      final initialState = container.read(gameProvider);
      expect(initialState.myHand.length, 5);
      expect(initialState.isMyTurn, isTrue);

      // Select and play first card
      gameNotifier.selectCard(0);
      expect(container.read(gameProvider).selectedCardIndex, 0);

      gameNotifier.playSelectedCard();

      // Hand decreases immediately
      final afterPlayState = container.read(gameProvider);
      expect(afterPlayState.myHand.length, 4);
      expect(afterPlayState.isMyTurn, isFalse);

      // Advance simulated timers (bot turn 700ms + trick resolution 900ms)
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1000));

      // After round trick finishes, user can play next card
      expect(container.read(gameProvider).isMyTurn, isTrue);

      container.dispose();
    });
  });

  group('Demo Mode UI Widget Integration', () {
    testWidgets('NameScreen renders Demo Mode indicator and inputs',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: NameScreen()),
        ),
      );

      expect(find.text('WIZARD'), findsOneWidget);
      expect(find.text('DEMO MODE ACTIVE (No Server)'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('ServerListScreen displays demo rooms and Demo badge',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('DEMO MODE'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('🐉 Dragon\'s Keep'), findsOneWidget);
    });

    testWidgets('RoomLobbyScreen renders demo players and Start Game button',
        (tester) async {
      final container = ProviderContainer();
      container.read(playerNameProvider.notifier).setName('DemoHero');
      container
          .read(currentRoomProvider.notifier)
          .createRoom('Lobby Test Room', 4);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RoomLobbyScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lobby Test Room'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('DemoHero'), findsOneWidget);
      expect(find.text('Merlin'), findsOneWidget);
    });

    testWidgets('GameResultScreen displays winner and final standings',
        (tester) async {
      final container = ProviderContainer();
      container.read(playerNameProvider.notifier).setName('Champion');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GameResultScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Over'), findsOneWidget);
      expect(find.text('DEMO MATCH RESULT'), findsOneWidget);
      expect(find.text('Champion'), findsOneWidget);
      expect(find.text('Back to Rooms'), findsOneWidget);
    });

    testWidgets(
        'CreateRoomScreen renders player counts 2 to 8 and creates 8-player room',
        (tester) async {
      final container = ProviderContainer();
      container.read(playerNameProvider.notifier).setName('HostPlayer');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CreateRoomScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check player selectors from 2 to 8 exist
      for (int i = 2; i <= 8; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap on 8 players
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();

      expect(find.text('8 players'), findsOneWidget);

      // Tap Create Room button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      final currentRoom = container.read(currentRoomProvider);
      expect(currentRoom, isNotNull);
      expect(currentRoom!.maxPlayers, 8);
    });
  });
}
