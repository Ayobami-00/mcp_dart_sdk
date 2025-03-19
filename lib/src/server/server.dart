/// Main server implementation for the Model Context Protocol.
import 'dart:async';

import 'package:logging/logging.dart';

import '../base/session.dart';
import '../base/types.dart';
import '../base/lifecycle.dart';
import '../shared/exceptions.dart';
import '../shared/context.dart';
import 'session.dart';

/// The main server class for the MCP protocol.
class McpServer {
  final Logger _logger = Logger('McpServer');
  final ServerInfo _serverInfo;
  final ServerCapabilities _serverCapabilities;

  ServerSession? _session;
  final Map<String, RequestHandler> _methodHandlers = {};

  /// Request context factory.
  final ServerRequestContextFactory contextFactory;

  /// Creates a new [McpServer] instance.
  McpServer({
    required ServerInfo serverInfo,
    required ServerCapabilities capabilities,
    ServerRequestContextFactory? contextFactory,
  })  : _serverInfo = serverInfo,
        _serverCapabilities = capabilities,
        contextFactory = contextFactory ?? ServerRequestContextFactory();

  /// The client information.
  ClientInfo? get clientInfo => _session?.clientInfo;

  /// The client capabilities.
  ClientCapabilities? get clientCapabilities => _session?.clientCapabilities;

  /// Whether the server is running.
  bool get isRunning => _session != null;

  /// Whether the server is initialized.
  bool get isInitialized => _session?.state == SessionState.initialized;

  /// Starts the server using the given transport.
  Future<void> start(Transport transport) async {
    if (_session != null) {
      throw StateError('Server is already running');
    }

    _session = ServerSession(
      transport,
      serverInfo: _serverInfo,
      serverCapabilities: _serverCapabilities,
    );

    // Register method handlers
    for (final entry in _methodHandlers.entries) {
      _session!.registerMethodHandler(entry.key, entry.value);
    }

    // Set the default request handler
    _session!.requestHandler = _handleRequest;

    _logger.info('Server started');
  }

  /// Stops the server.
  Future<void> stop() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
      _logger.info('Server stopped');
    }
  }

  /// Registers a handler for a method.
  void registerMethodHandler(String method, RequestHandler handler) {
    _methodHandlers[method] = handler;

    // If the session is running, register the handler with the session
    if (_session != null) {
      _session!.registerMethodHandler(method, handler);
    }
  }

  /// Handles a request from the client.
  Future<dynamic> _handleRequest(String method, dynamic params) async {
    // This handler is called for methods that don't have a specific handler
    _logger.warning('No handler registered for method: $method');
    throw MethodNotFoundException(method);
  }

  /// Sends a notification to the client.
  Future<void> sendNotification(String method, [dynamic params]) async {
    _checkRunning();
    await _session!.sendNotification(method, params);
  }

  /// Sends a request to the client and returns the response.
  Future<dynamic> sendRequest(String method, [dynamic params]) async {
    _checkRunning();
    return await _session!.sendRequest(method, params);
  }

  /// Checks if a capability is supported by the client.
  bool isCapabilitySupported(String capability) {
    _checkRunning();
    return _session!.isCapabilitySupported(capability);
  }

  /// Checks if the server is running.
  void _checkRunning() {
    if (_session == null) {
      throw StateError('Server is not running');
    }
  }
}
