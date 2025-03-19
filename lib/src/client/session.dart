/// Client session implementation for the Model Context Protocol.
import 'dart:async';

import 'package:logging/logging.dart';

import '../base/json_rpc.dart';
import '../base/lifecycle.dart';
import '../base/session.dart';
import '../base/types.dart';
import '../shared/context.dart';
import '../shared/exceptions.dart';

/// Type alias for client lifespan context.
typedef ClientLifespanContext = Map<String, dynamic>;

/// Client session for the MCP protocol.
class ClientSession extends BaseSession {
  final Logger _logger = Logger('ClientSession');

  /// The server information.
  ServerInfo? serverInfo;

  /// The server capabilities.
  ServerCapabilities? serverCapabilities;

  /// Creates a new [ClientSession] instance.
  ClientSession(Transport transport) : super(transport) {
    // Listen for notifications
    notifications.listen(_handleNotification);
  }

  /// Initializes the session with the server.
  Future<InitializeResult> initialize({
    required ClientInfo clientInfo,
    required ClientCapabilities capabilities,
  }) async {
    if (state != SessionState.uninitialized) {
      throw StateError('Session is already initialized');
    }

    final params = InitializeParams(
      clientInfo: clientInfo,
      capabilities: capabilities,
    );

    final result =
        await sendRequest(LifecycleMethods.initialize, params.toJson());

    final initResult =
        InitializeResult.fromJson(result as Map<String, dynamic>);

    serverInfo = initResult.serverInfo;
    serverCapabilities = initResult.capabilities;

    // Update session state to initialized
    sessionState = SessionState.initialized;
    _logger.info(
        'Initialized session with server: ${serverInfo?.name} ${serverInfo?.version}');

    return initResult;
  }

  /// Shuts down the session.
  Future<void> shutdown() async {
    if (state != SessionState.initialized) {
      throw StateError('Session is not initialized');
    }

    // Update session state to shuttingDown
    sessionState = SessionState.shuttingDown;

    final params = ShutdownParams();

    await sendRequest(LifecycleMethods.shutdown, params.toJson());

    // Update session state to shutdown
    sessionState = SessionState.shutdown;
    _logger.info('Shut down session');
  }

  /// Exits the session.
  Future<void> exit() async {
    if (state != SessionState.shutdown && state != SessionState.initialized) {
      throw StateError('Session is not initialized or shut down');
    }

    final params = ExitParams();

    await sendNotification(LifecycleMethods.exit, params.toJson());

    // Update session state to exited
    sessionState = SessionState.exited;

    await close();
    _logger.info('Exited session');
  }

  /// Checks if a capability is supported by the server.
  bool isCapabilitySupported(String capability) {
    if (serverCapabilities == null) {
      return false;
    }

    switch (capability) {
      case 'prompts':
        return serverCapabilities!.prompts != null;
      case 'resources':
        return serverCapabilities!.resources != null;
      case 'tools':
        return serverCapabilities!.tools != null;
      case 'logging':
        return serverCapabilities!.logging != null;
      default:
        return false;
    }
  }

  /// Handles an incoming notification.
  void _handleNotification(JsonRpcNotification notification) {
    // Handle different types of notifications
    switch (notification.method) {
      // No built-in notifications to handle yet
      default:
        _logger.fine('Received notification: ${notification.method}');
        break;
    }
  }
}

/// Context factory for client sessions.
class ClientRequestContextFactory
    extends RequestContextFactory<ClientSession, ClientLifespanContext> {
  /// Creates a new [ClientRequestContextFactory] instance.
  ClientRequestContextFactory()
      : super(createLifespanContext: () => <String, dynamic>{});
}
