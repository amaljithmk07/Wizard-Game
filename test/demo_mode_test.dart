import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizard_flutter/core/config/app_config.dart';
import 'package:wizard_flutter/core/network/socket_service.dart';
import 'package:wizard_flutter/models/game_card.dart';
import 'package:wizard_flutter/models/game_room.dart';
import 'package:wizard_flutter/models/player.dart';
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
  });

  tearDown(() {
    SocketService().disconnect();
  });

  group('Online App Configuration & Network Guards', () {
    test('Default server URL points to production Render server', () {
      expect(AppConfig.defaultServerUrl, 'wss://wizard-game-sk6k.onrender.com');
      expect(AppConfig.serverUrl, contains('onrender.com'));
      expect(AppConfig.isDemoMode, isFalse);
    });

    test('Custom server URL can be configured', () {
      AppConfig.setServerUrl('wss://custom-server.com');
      expect(AppConfig.serverUrl, 'wss://custom-server.com');
      AppConfig.setServerUrl(AppConfig.defaultServerUrl);
    });
  });

  group('Screen UI Integration Tests', () {
    testWidgets('NameScreen renders title and player input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: NameScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('ServerListScreen displays rooms header and actions',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join by IP'), findsOneWidget);
      // Mock data should NOT be shown
      expect(find.text('🐉 Dragon\'s Keep'), findsNothing);
      expect(find.text('⚡ Lightning Arena'), findsNothing);
    });

    testWidgets(
        'CreateRoomScreen renders player counts 3 to 8 (Official Rule 1)',
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

      // Check player selectors from 3 to 8 exist (Rule 1: 3-8 players)
      for (int i = 3; i <= 8; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(find.text('6 players'), findsOneWidget);
    });

    testWidgets('RoomLobbyScreen renders room details and player list',
        (tester) async {
      final container = ProviderContainer();
      final testRoom = GameRoom(
        id: 'real_room_1',
        name: 'Thunder Room',
        hostId: 'p1',
        maxPlayers: 4,
        playerCount: 2,
        status: 'WAITING',
        players: [
          Player(id: 'p1', name: 'CalicutHost', isHost: true),
          Player(id: 'p2', name: 'ChennaiFriend', isHost: false),
        ],
      );

      container.read(currentRoomProvider.notifier).state = testRoom;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RoomLobbyScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thunder Room'), findsOneWidget);
      expect(find.text('CalicutHost'), findsOneWidget);
      expect(find.text('ChennaiFriend'), findsOneWidget);
      // No fake Merlin bot
      expect(find.text('Merlin'), findsNothing);
    });

    testWidgets('GameResultScreen displays game over and winner',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GameResultScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Over'), findsOneWidget);
      expect(find.text('Back to Rooms'), findsOneWidget);
    });
  });
}
