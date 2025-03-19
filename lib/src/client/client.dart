/// Main client implementation for the Model Context Protocol.
import 'dart:async';

import 'package:logging/logging.dart';

import '../base/lifecycle.dart';
import '../base/session.dart';
import '../base/types.dart';
import '../shared/exceptions.dart';
import 'capabilities/roots.dart';
import 'capabilities/sampling.dart';
import 'session.dart';

/// The main client class for the MCP protocol.
class McpClient {
  final Logger _logger = Logger('McpClient');
  ClientSession? _session;

  /// The server information.
  ServerInfo? get serverInfo => _session?.serverInfo;

  /// The server capabilities.
  ServerCapabilities? get serverCapabilities => _session?.serverCapabilities;

  /// Whether the client is connected to a server.
  bool get isConnected => _session != null;

  /// Whether the client is initialized.
  bool get isInitialized => _session?.state == SessionState.initialized;

  /// The current client session.
  ///
  /// This is exposed for capability extensions to access.
  ///
  /// Note: This is intended for internal use by capability extensions.
  ClientSession? get session => _session;

  /// Creates a new [McpClient] instance.
  McpClient();

  /// Connects to a server using the given transport.
  Future<void> connect(Transport transport) async {
    if (_session != null) {
      throw StateError('Already connected to a server');
    }

    _session = ClientSession(transport);
    _logger.info('Connected to server');
  }

  /// Initializes the session with the server.
  ///
  /// You can provide specific capability implementations using the [rootsCapability]
  /// and [samplingCapability] parameters, or create a custom [ClientCapabilities]
  /// instance directly.
  Future<ServerCapabilities> initialize({
    required ClientInfo clientInfo,
    ClientCapabilities? capabilities,
    RootsCapability? rootsCapability,
    SamplingCapability? samplingCapability,
  }) async {
    _checkConnected();

    // Use either the provided capabilities or create from individual capabilities
    final clientCapabilities = capabilities ??
        ClientCapabilities.withCapabilities(
          rootsCapability: rootsCapability,
          samplingCapability: samplingCapability,
        );

    final result = await _session!.initialize(
      clientInfo: clientInfo,
      capabilities: clientCapabilities,
    );

    return result.capabilities;
  }

  /// Shuts down the session.
  Future<void> shutdown() async {
    _checkConnected();
    _checkInitialized();

    await _session!.shutdown();
  }

  /// Exits the session.
  Future<void> exit() async {
    _checkConnected();

    await _session!.exit();
    _session = null;
  }

  /// Closes the connection to the server.
  Future<void> close() async {
    if (_session != null) {
      if (_session!.state == SessionState.initialized) {
        await shutdown();
      }

      await _session!.close();
      _session = null;
    }
  }

  /// Checks if a capability is supported by the server.
  bool isCapabilitySupported(String capability) {
    _checkConnected();
    return _session!.isCapabilitySupported(capability);
  }

  /// Sends a custom request to the server.
  Future<dynamic> sendRequest(String method, [dynamic params]) async {
    _checkConnected();
    _checkInitialized();

    return await _session!.sendRequest(method, params);
  }

  /// Sends a custom notification to the server.
  Future<void> sendNotification(String method, [dynamic params]) async {
    _checkConnected();
    _checkInitialized();

    await _session!.sendNotification(method, params);
  }

  /// Checks if the client is connected to a server.
  void _checkConnected() {
    if (_session == null) {
      throw StateError('Not connected to a server');
    }
  }

  /// Checks if the session is initialized.
  void _checkInitialized() {
    if (_session?.state != SessionState.initialized) {
      throw StateError('Session is not initialized');
    }
  }
}
