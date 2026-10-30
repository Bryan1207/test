import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../model/game_state.dart';

enum ConnectionStage { idle, hosting, connecting, connected, disconnected }
enum PlayerRole { host, guest }

/// One TCP socket per match. Traffic is transported over the OS network stack:
/// a LAN address on Wi-Fi, or a Tailscale 100.x address across cellular.
/// The host alone decides whether moves are legal and publishes full state.
class GameSession extends ChangeNotifier {
  static const int port = 45454;

  ServerSocket? _server;
  Socket? _peer;
  StreamSubscription<Socket>? _acceptSubscription;
  StreamSubscription<String>? _messages;
  bool _disposed = false;
  bool _awaitingMove = false;

  ConnectionStage stage = ConnectionStage.idle;
  PlayerRole? role;
  GameState game = GameState.initial();
  String message = 'Host a match or join by IP address.';
  String connectedTo = '';

  bool get isHost => role == PlayerRole.host;
  String get mySymbol => isHost ? 'X' : 'O';
  bool get isMyTurn => stage == ConnectionStage.connected &&
      !game.finished && game.turn == mySymbol;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> host() async {
    await leave();
    role = PlayerRole.host;
    game = GameState.initial();
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      stage = ConnectionStage.hosting;
      message = 'Waiting for a friend. Share your Tailscale IP and port $port.';
      _acceptSubscription = _server!.listen((socket) {
        if (_peer != null) {
          socket.writeln(jsonEncode({'type': 'error', 'message': 'Match is full'}));
          socket.close();
          return;
        }
        _attach(socket);
        stage = ConnectionStage.connected;
        connectedTo = socket.remoteAddress.address;
        message = 'Player O joined. You play X and move first.';
        _sendState();
        _notify();
      }, onError: (Object error) {
        message = 'Host network error: $error';
        _notify();
      });
    } on SocketException catch (error) {
      stage = ConnectionStage.disconnected;
      message = 'Could not host on port $port: ${error.message}';
    }
    _notify();
  }

  Future<void> join(String address) async {
    final hostname = address.trim();
    if (hostname.isEmpty || hostname.contains(RegExp(r'\s|/|:'))) {
      message = 'Enter your host\'s Tailscale IPv4 address (for example, 100.101.102.103).';
      _notify();
      return;
    }
    await leave();
    role = PlayerRole.guest;
    stage = ConnectionStage.connecting;
    message = 'Connecting to $hostname:$port…';
    _notify();
    try {
      final socket = await Socket.connect(
        hostname,
        port,
        timeout: const Duration(seconds: 12),
      );
      _attach(socket);
      stage = ConnectionStage.connected;
      connectedTo = hostname;
      message = 'Connected. You play O; the host moves first.';
    } on SocketException catch (error) {
      stage = ConnectionStage.disconnected;
      message = 'Connection failed: ${error.message}. Check Tailscale on both phones.';
    } on TimeoutException {
      stage = ConnectionStage.disconnected;
      message = 'Connection timed out. Check the IP and that the host is waiting.';
    }
    _notify();
  }

  void _attach(Socket socket) {
    _peer = socket;
    _awaitingMove = false;
    _messages = socket
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: _onDisconnected, onError: (Object error) {
      message = 'Connection error: $error';
      _onDisconnected();
    }, cancelOnError: true);
  }

  void _send(Map<String, dynamic> payload) {
    final peer = _peer;
    if (peer == null) return;
    try {
      peer.writeln(jsonEncode(payload));
    } on SocketException {
      _onDisconnected();
    }
  }

  void _sendState() => _send({'type': 'state', 'game': game.toJson()});

  void _onLine(String line) {
    // Local prototype protocol: refuse unreasonably large messages.
    if (line.length > 8192) return;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'];
      if (isHost) {
        if (type == 'move' && decoded['index'] is int) {
          final next = game.move(decoded['index'] as int, 'O');
          if (next != null) {
            game = next;
            _sendState();
            _notify();
          }
        } else if (type == 'rematch' && game.finished) {
          game = game.nextRound();
          _sendState();
          _notify();
        }
      } else {
        if (type == 'state' && decoded['game'] is Map<String, dynamic>) {
          game = GameState.fromJson(decoded['game'] as Map<String, dynamic>);
          _awaitingMove = false;
          _notify();
        } else if (type == 'error') {
          message = decoded['message']?.toString() ?? 'Host rejected connection.';
          _notify();
        }
      }
    } on FormatException {
      // Ignore invalid packets. The host remains authoritative.
    }
  }

  void play(int index) {
    if (!isMyTurn) return;
    if (isHost) {
      final next = game.move(index, 'X');
      if (next == null) return;
      game = next;
      _sendState();
      _notify();
    } else if (!_awaitingMove && game.canMove(index, 'O')) {
      _awaitingMove = true;
      _send({'type': 'move', 'index': index});
      _notify();
    }
  }

  void rematch() {
    if (stage != ConnectionStage.connected || !game.finished) return;
    if (isHost) {
      game = game.nextRound();
      _sendState();
      _notify();
    } else {
      message = 'Requested the next round…';
      _send({'type': 'rematch'});
      _notify();
    }
  }

  void _onDisconnected() {
    _peer?.destroy();
    _peer = null;
    _messages = null;
    _awaitingMove = false;
    connectedTo = '';
    if (isHost && _server != null) {
      stage = ConnectionStage.hosting;
      game = GameState.initial();
      message = 'Guest left. Waiting for another connection…';
    } else {
      stage = ConnectionStage.disconnected;
      message = 'Disconnected from host. You can join again.';
    }
    _notify();
  }

  Future<void> leave() async {
    final messages = _messages;
    final accepts = _acceptSubscription;
    final server = _server;
    final peer = _peer;
    _messages = null;
    _acceptSubscription = null;
    _server = null;
    _peer = null;
    await messages?.cancel();
    await accepts?.cancel();
    peer?.destroy();
    await server?.close();
    role = null;
    stage = ConnectionStage.idle;
    connectedTo = '';
    _awaitingMove = false;
    message = 'Host a match or join by IP address.';
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _messages?.cancel();
    _acceptSubscription?.cancel();
    _peer?.destroy();
    _server?.close();
    super.dispose();
  }
}
