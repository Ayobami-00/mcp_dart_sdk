/// WebSocket transport for MCP server.
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../../src/base/session.dart';
import '../../../src/shared/exceptions.dart';

/// Configuration for the WebSocket server transport.
class WebSocketServerConfig {
  /// The port to listen on.
  final int port;

  /// The bind address.
  final String address;

  /// The WebSocket path.
  final String path;

  /// Creates a new [WebSocketServerConfig] instance.
  const WebSocketServerConfig({
    this.port = 8000,
    this.address = 'localhost',
    this.path = '/ws',
  });
}

/// A transport implementation that uses WebSockets for bidirectional
/// communication with multiple clients.
class WebSocketServerTransport implements Transport {
  final Logger _logger = Logger('WebSocketServerTransport');
  final WebSocketServerConfig _config;
  final StreamController<String> _incomingController =
      StreamController<String>();
  final List<WebSocket> _clients = [];

  HttpServer? _server;

  /// Creates a new [WebSocketServerTransport] instance.
  WebSocketServerTransport({
    WebSocketServerConfig? config,
  }) : _config = config ?? const WebSocketServerConfig();

  @override
  Stream<String> get incoming => _incomingController.stream;

  /// Starts the WebSocket server.
  Future<void> start() async {
    try {
      _server = await HttpServer.bind(_config.address, _config.port);
      _logger.info(
          'WebSocket server listening on ${_config.address}:${_config.port}');

      _server!.listen(_handleRequest);
    } catch (e) {
      _logger.severe('Failed to start WebSocket server: $e');
      throw TransportException('Failed to start WebSocket server: $e');
    }
  }

  @override
  Future<void> send(String message) async {
    // We'll collect clients that should be removed
    final toRemove = <WebSocket>[];

    // Send the message to all connected clients
    for (final client in _clients) {
      try {
        client.add(message);
      } catch (e) {
        _logger.warning('Failed to send message to client: $e');
        toRemove.add(client);
      }
    }

    // Remove clients that failed
    _clients.removeWhere((client) => toRemove.contains(client));
  }

  @override
  Future<void> close() async {
    // Close all client connections
    for (final client in _clients) {
      await client.close(WebSocketStatus.normalClosure, 'Server closing');
    }
    _clients.clear();

    // Close the server
    await _server?.close(force: true);
    _server = null;

    // Close the incoming controller
    await _incomingController.close();

    _logger.info('WebSocket server transport closed');
  }

  /// Handles an incoming HTTP request and upgrades it to a WebSocket.
  void _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // Only handle WebSocket requests to the configured path
    if (path != _config.path) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    // Handle WebSocket upgrade
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      _handleWebSocket(socket);
    } catch (e) {
      _logger.warning('Failed to upgrade WebSocket connection: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  /// Handles a WebSocket connection.
  void _handleWebSocket(WebSocket socket) {
    // Add to list of clients
    _clients.add(socket);

    // Set up message handler
    socket.listen(
      (dynamic data) {
        if (data is String) {
          _incomingController.add(data);
        } else {
          _logger.warning('Received non-string message: $data');
        }
      },
      onDone: () {
        _clients.remove(socket);
        _logger.info('WebSocket connection closed');
      },
      onError: (error) {
        _clients.remove(socket);
        _logger.warning('WebSocket error: $error');
      },
    );

    // Set up ping/pong for keep-alive
    socket.pingInterval = Duration(seconds: 30);
  }
}
