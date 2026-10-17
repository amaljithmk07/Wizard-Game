import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocket? _webSocket;
  final ValueNotifier<SocketConnectionStatus> statusNotifier =
      ValueNotifier<SocketConnectionStatus>(
          SocketConnectionStatus.disconnected);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _socketId;
  String? get socketId => _socketId ?? 'player_client';

  bool get isConnected =>
      _webSocket != null && _webSocket!.readyState == WebSocket.open;

  final Map<String, List<Function(dynamic)>> _listeners = {};

  bool _isTestEnvironment() {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> connect({String? serverUrl}) async {
    if (AppConfig.isDemoMode || _isTestEnvironment()) {
      if (kDebugMode) {
        print('[SocketService] Connection skipped (Demo Mode or Test).');
      }
      return;
    }

    final targetUrl = (serverUrl != null && serverUrl.isNotEmpty)
        ? serverUrl
        : AppConfig.serverUrl;

    // Convert http:// to ws:// if provided
    String wsUrl = targetUrl;
    if (wsUrl.startsWith('http://')) {
      wsUrl = 'ws://${wsUrl.substring(7)}';
    } else if (wsUrl.startsWith('https://')) {
      wsUrl = 'wss://${wsUrl.substring(8)}';
    } else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
      wsUrl = 'ws://$wsUrl';
    }

    disconnect();

    statusNotifier.value = SocketConnectionStatus.connecting;
    _errorMessage = null;

    try {
      _webSocket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection to $wsUrl timed out');
        },
      );

      _socketId = 'client_${DateTime.now().microsecondsSinceEpoch}';
      statusNotifier.value = SocketConnectionStatus.connected;

      if (kDebugMode) {
        print(
            '[SocketService] Connected to host at $wsUrl (ID: $_socketId)');
      }

      _webSocket!.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            final event = decoded['event'] as String?;
            final payload = decoded['data'];

            if (event != null && _listeners.containsKey(event)) {
              for (final handler in List.from(_listeners[event]!)) {
                try {
                  handler(payload);
                } catch (e) {
                  if (kDebugMode) {
                    print('[SocketService] Handler error for $event: $e');
                  }
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('[SocketService] Error decoding message: $e');
            }
          }
        },
        onDone: () {
          statusNotifier.value = SocketConnectionStatus.disconnected;
          if (kDebugMode) {
            print('[SocketService] Disconnected from host');
          }
        },
        onError: (err) {
          statusNotifier.value = SocketConnectionStatus.error;
          _errorMessage = 'Socket error: $err';
          if (kDebugMode) {
            print('[SocketService] Connection error: $err');
          }
        },
      );
    } catch (e) {
      statusNotifier.value = SocketConnectionStatus.error;
      _errorMessage = 'Could not connect to host at $serverUrl';
      if (kDebugMode) {
        print('[SocketService] Failed to connect: $e');
      }
    }
  }

  void disconnect() {
    try {
      _webSocket?.close();
    } catch (_) {}
    _webSocket = null;
    statusNotifier.value = SocketConnectionStatus.disconnected;
  }

  void on(String event, Function(dynamic) handler) {
    if (AppConfig.isDemoMode) return;
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  void off(String event) {
    if (AppConfig.isDemoMode) return;
    _listeners.remove(event);
  }

  void emit(String event, [dynamic data]) {
    if (AppConfig.isDemoMode) return;

    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      try {
        final payload = jsonEncode({'event': event, 'data': data ?? {}});
        _webSocket!.add(payload);
      } catch (e) {
        if (kDebugMode) {
          print('[SocketService] Error emitting $event: $e');
        }
      }
    }
  }
}
