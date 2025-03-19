/// Server session implementation for the Model Context Protocol.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../base/json_rpc.dart';
import '../base/lifecycle.dart';
import '../base/session.dart';
import '../base/types.dart';
import '../shared/context.dart';
import '../shared/exceptions.dart';

/// Type alias for server lifespan context.
typedef ServerLifespanContext = Map<String, dynamic>;

/// Server session for the MCP protocol.
class ServerSession extends BaseSession {
  final Logger _logger = Logger('ServerSession');

  /// The client information.
  ClientInfo? clientInfo;

  /// The client capabilities.
  ClientCapabilities? clientCapabilities;

  /// The server information.
  final ServerInfo serverInfo;

  /// The server capabilities.
  final ServerCapabilities serverCapabilities;

  /// Map of method handlers.
  final Map<String, RequestHandler> _methodHandlers = {};

  /// Creates a new [ServerSession] instance.
  ServerSession(
    Transport transport, {
    required this.serverInfo,
    required this.serverCapabilities,
  }) : super(transport) {
    // Register the standard method handlers
    _registerDefaultHandlers();

    // Listen for notifications
    notifications.listen(_handleNotification);
  }

  /// Registers a handler for a method.
  void registerMethodHandler(String method, RequestHandler handler) {
    _methodHandlers[method] = handler;
  }

  /// Handles a method call.
  @override
  set requestHandler(RequestHandler handler) {
    super.requestHandler = (method, params) async {
      // Check if we have a registered handler for this method
      final methodHandler = _methodHandlers[method];
      if (methodHandler != null) {
        return await methodHandler(method, params);
      }

      // Fall back to the default handler
      return await handler(method, params);
    };
  }

  /// Registers the default method handlers.
  void _registerDefaultHandlers() {
    // Register initialize handler
    registerMethodHandler(LifecycleMethods.initialize, _handleInitialize);

    // Register shutdown handler
    registerMethodHandler(LifecycleMethods.shutdown, _handleShutdown);
  }

  /// Handles the initialize request.
  Future<dynamic> _handleInitialize(String method, dynamic params) async {
    if (sessionState != SessionState.uninitialized) {
      throw StateError('Session is already initialized');
    }

    final initParams =
        InitializeParams.fromJson(params as Map<String, dynamic>);

    clientInfo = initParams.clientInfo;
    clientCapabilities = initParams.capabilities;

    sessionState = SessionState.initialized;
    _logger.info(
        'Initialized session with client: ${clientInfo?.name} ${clientInfo?.version}');

    return InitializeResult(
      serverInfo: serverInfo,
      capabilities: serverCapabilities,
    ).toJson();
  }

  /// Handles the shutdown request.
  Future<dynamic> _handleShutdown(String method, dynamic params) async {
    if (sessionState != SessionState.initialized) {
      throw StateError('Session is not initialized');
    }

    sessionState = SessionState.shutdown;
    _logger.info('Shut down session');

    return ShutdownResult().toJson();
  }

  /// Handles an incoming notification.
  void _handleNotification(JsonRpcNotification notification) {
    // Handle exit notification
    if (notification.method == LifecycleMethods.exit) {
      sessionState = SessionState.exited;
      _logger.info('Received exit notification');
    }
  }

  /// Checks if a capability is supported by the client.
  bool isCapabilitySupported(String capability) {
    if (clientCapabilities == null) {
      return false;
    }

    switch (capability) {
      case 'roots':
        return clientCapabilities!.roots != null;
      case 'sampling':
        return clientCapabilities!.sampling != null;
      default:
        return false;
    }
  }
}

/// Context factory for server sessions.
class ServerRequestContextFactory
    extends RequestContextFactory<ServerSession, ServerLifespanContext> {
  /// Creates a new [ServerRequestContextFactory] instance.
  ServerRequestContextFactory()
      : super(createLifespanContext: () => <String, dynamic>{});
}
