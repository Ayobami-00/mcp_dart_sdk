/// WebSocket transport for MCP client.
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../../src/base/session.dart';
import '../../../src/shared/exceptions.dart';

/// A transport implementation that uses WebSockets for bidirectional
/// communication with the server.
class WebSocketTransport implements Transport {
  final Logger _logger = Logger('WebSocketTransport');
  final String _url;
  final Duration _connectionTimeout;
  final Map<String, dynamic> _headers;

  WebSocket? _socket;
  final StreamController<String> _incomingController =
      StreamController<String>();
  Completer<void>? _connectCompleter;
  Timer? _pingTimer;

  /// Creates a new [WebSocketTransport] instance.
  WebSocketTransport({
    required String url,
    Duration connectionTimeout = const Duration(seconds: 30),
    Map<String, dynamic>? headers,
  })  : _url = url,
        _connectionTimeout = connectionTimeout,
        _headers = headers ?? {};

  @override
  Stream<String> get incoming => _incomingController.stream;

  /// Connects to the WebSocket server.
  Future<void> connect() async {
    if (_socket != null) {
      return;
    }

    if (_connectCompleter != null) {
      return _connectCompleter!.future;
    }

    _connectCompleter = Completer<void>();

    try {
      _socket = await WebSocket.connect(
        _url,
        headers: _headers,
      ).timeout(_connectionTimeout);

      _socket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _startPingTimer();

      _logger.info('Connected to WebSocket server: $_url');
      _connectCompleter!.complete();
    } catch (e) {
      _logger.severe('Failed to connect to WebSocket server: $e');
      _connectCompleter!.completeError(
        TransportException('Failed to connect to WebSocket server: $e'),
      );
      _connectCompleter = null;
      rethrow;
    }

    return _connectCompleter!.future;
  }

  @override
  Future<void> send(String message) async {
    if (_socket == null) {
      await connect();
    }

    try {
      _socket!.add(message);
    } catch (e) {
      _logger.severe('Failed to send message: $e');
      throw TransportException('Failed to send message: $e');
    }
  }

  @override
  Future<void> close() async {
    _stopPingTimer();

    if (_socket != null) {
      await _socket!
          .close(WebSocketStatus.normalClosure, 'Client closing connection');
      _socket = null;
    }

    await _incomingController.close();
  }

  /// Handles an incoming message.
  void _handleMessage(dynamic message) {
    if (message is String) {
      _incomingController.add(message);
    } else {
      _logger.warning('Received non-string message: $message');
    }
  }

  /// Handles an error from the WebSocket.
  void _handleError(Object error) {
    _logger.warning('WebSocket error: $error');
    _incomingController.addError(error);
  }

  /// Handles the WebSocket closing.
  void _handleDone() {
    _logger.info('WebSocket connection closed');
    _stopPingTimer();

    if (!_incomingController.isClosed) {
      _incomingController.addError(
        TransportException('WebSocket connection closed unexpectedly'),
      );
    }

    _socket = null;
  }

  /// Starts the ping timer to keep the connection alive.
  void _startPingTimer() {
    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_socket != null && _socket!.readyState == WebSocket.open) {
        try {
          // Send an empty ping frame
          _socket!.add('');
        } catch (e) {
          _logger.warning('Failed to send ping: $e');
        }
      }
    });
  }

  /// Stops the ping timer.
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
}
