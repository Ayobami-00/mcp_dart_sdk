/// HTTP with Server-Sent Events transport for MCP server.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../../src/base/session.dart';
import '../../../src/shared/exceptions.dart';

/// Configuration for the HTTP SSE transport.
class HttpSseServerConfig {
  /// The port to listen on.
  final int port;

  /// The bind address.
  final String address;

  /// The path for the SSE endpoint.
  final String ssePath;

  /// The path for the POST endpoint.
  final String postPath;

  /// Creates a new [HttpSseServerConfig] instance.
  const HttpSseServerConfig({
    this.port = 8000,
    this.address = 'localhost',
    this.ssePath = '/events',
    this.postPath = '/send',
  });
}

/// A transport implementation that uses HTTP with Server-Sent Events for server-to-client
/// communication and HTTP POST for client-to-server communication.
class HttpSseServerTransport implements Transport {
  final Logger _logger = Logger('HttpSseServerTransport');
  final HttpSseServerConfig _config;
  final StreamController<String> _incomingController =
      StreamController<String>();
  final List<HttpResponse> _clients = [];

  HttpServer? _server;

  /// Creates a new [HttpSseServerTransport] instance.
  HttpSseServerTransport({
    HttpSseServerConfig? config,
  }) : _config = config ?? const HttpSseServerConfig();

  @override
  Stream<String> get incoming => _incomingController.stream;

  /// Starts the HTTP server.
  Future<void> start() async {
    try {
      _server = await HttpServer.bind(_config.address, _config.port);
      _logger
          .info('HTTP server listening on ${_config.address}:${_config.port}');

      _server!.listen(_handleRequest);
    } catch (e) {
      _logger.severe('Failed to start HTTP server: $e');
      throw TransportException('Failed to start HTTP server: $e');
    }
  }

  @override
  Future<void> send(String message) async {
    // Send to all connected clients
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // We'll collect responses that should be removed
    final toRemove = <HttpResponse>[];

    // Send the message to all connected clients
    for (final client in _clients) {
      try {
        client.write('id: $timestamp\n');
        client.write('data: $message\n\n');
        await client.flush();
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
      await client.close();
    }
    _clients.clear();

    // Close the server
    await _server?.close(force: true);
    _server = null;

    // Close the incoming controller
    await _incomingController.close();

    _logger.info('HTTP SSE transport closed');
  }

  /// Handles an incoming HTTP request.
  void _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // Handle SSE requests
    if (path == _config.ssePath && request.method == 'GET') {
      await _handleSseRequest(request);
      return;
    }

    // Handle POST requests
    if (path == _config.postPath && request.method == 'POST') {
      await _handlePostRequest(request);
      return;
    }

    // Return 404 for other requests
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  /// Handles an SSE request.
  Future<void> _handleSseRequest(HttpRequest request) async {
    // Set headers for SSE
    request.response.headers.set('Content-Type', 'text/event-stream');
    request.response.headers.set('Cache-Control', 'no-cache');
    request.response.headers.set('Connection', 'keep-alive');
    request.response.headers.set('Access-Control-Allow-Origin', '*');

    // Keep the connection open
    _clients.add(request.response);

    // Send a ping to keep the connection alive
    final pingTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        request.response.write('event: ping\n');
        request.response.write(
            'data: {"time": ${DateTime.now().millisecondsSinceEpoch}}\n\n');
        await request.response.flush();
      } catch (e) {
        _logger.warning('Failed to send ping: $e');
        timer.cancel();
        _clients.remove(request.response);
      }
    });

    // Handle connection closed
    request.response.done.then((_) {
      _clients.remove(request.response);
      pingTimer.cancel();
    }).catchError((e) {
      _logger.warning('Error in SSE connection: $e');
      _clients.remove(request.response);
      pingTimer.cancel();
    });
  }

  /// Handles a POST request.
  Future<void> _handlePostRequest(HttpRequest request) async {
    try {
      // Set CORS headers
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers
          .set('Access-Control-Allow-Methods', 'POST, OPTIONS');
      request.response.headers
          .set('Access-Control-Allow-Headers', 'Content-Type');

      // Handle preflight requests
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      // Read the request body
      final body = await utf8.decoder.bind(request).join();

      // Add the message to the incoming stream
      _incomingController.add(body);

      // Send a success response
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({'status': 'success'}));
    } catch (e) {
      _logger.warning('Error handling POST request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({'error': e.toString()}));
    } finally {
      await request.response.close();
    }
  }
}
