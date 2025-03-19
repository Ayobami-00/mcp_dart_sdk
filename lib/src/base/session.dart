/// Base session implementation for the Model Context Protocol.
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'json_rpc.dart';
import 'lifecycle.dart';
import 'types.dart';
import '../shared/exceptions.dart';

/// A transport layer for MCP communication.
abstract class Transport {
  /// Stream of incoming messages.
  Stream<String> get incoming;

  /// Sends a message.
  Future<void> send(String message);

  /// Closes the transport.
  Future<void> close();
}

/// Handles a request from the other party.
typedef RequestHandler = Future<dynamic> Function(
    String method, dynamic params);

/// Base class for all MCP sessions.
abstract class BaseSession {
  final Logger _logger = Logger('McpSession');
  final Uuid _uuid = Uuid();
  final Transport _transport;

  final Map<RequestId, Completer<dynamic>> _pendingRequests = {};
  final StreamController<JsonRpcNotification> _notificationsController =
      StreamController<JsonRpcNotification>.broadcast();

  @protected
  SessionState sessionState = SessionState.uninitialized;
  RequestHandler? _requestHandler;

  /// Creates a new [BaseSession] instance.
  BaseSession(this._transport) {
    _transport.incoming.listen(_handleIncomingMessage, onError: _handleError);
  }

  /// Gets the current session state.
  SessionState get state => sessionState;

  /// Gets a stream of notifications.
  Stream<JsonRpcNotification> get notifications =>
      _notificationsController.stream;

  /// Sets the request handler.
  set requestHandler(RequestHandler handler) {
    _requestHandler = handler;
  }

  /// Generates a unique request ID.
  RequestId _generateRequestId() {
    return _uuid.v4();
  }

  /// Sends a request and returns a future that completes with the response.
  Future<dynamic> sendRequest(String method, [dynamic params]) async {
    final id = _generateRequestId();
    final request = JsonRpcRequest(
      id: id,
      method: method,
      params: params,
    );

    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    try {
      await _sendMessage(request);
    } catch (e) {
      _pendingRequests.remove(id);
      completer.completeError(e);
    }

    return completer.future;
  }

  /// Sends a notification.
  Future<void> sendNotification(String method, [dynamic params]) async {
    final notification = JsonRpcNotification(
      method: method,
      params: params,
    );

    await _sendMessage(notification);
  }

  /// Closes the session.
  Future<void> close() async {
    sessionState = SessionState.exited;

    final pendingRequests = _pendingRequests.values.toList();
    _pendingRequests.clear();

    for (final completer in pendingRequests) {
      completer.completeError(
        McpException('Session closed', ErrorCodes.requestCancelled),
      );
    }

    await _transport.close();
    await _notificationsController.close();
  }

  /// Handles an incoming message.
  void _handleIncomingMessage(String message) {
    Map<String, dynamic>? jsonMap;
    try {
      jsonMap = json.decode(message) as Map<String, dynamic>;
    } catch (e) {
      _logger.severe('Failed to parse JSON: $e');
      _sendErrorResponse(
        null,
        McpError(
          code: ErrorCodes.parseError,
          message: 'Invalid JSON: ${e.toString()}',
        ),
      );
      return;
    }

    try {
      final jsonRpcMessage = JsonRpcMessageFactory.fromJson(jsonMap);

      if (jsonRpcMessage is JsonRpcRequest) {
        _handleRequest(jsonRpcMessage);
      } else if (jsonRpcMessage is JsonRpcNotification) {
        _handleNotification(jsonRpcMessage);
      } else if (jsonRpcMessage is JsonRpcSuccessResponse) {
        _handleSuccessResponse(jsonRpcMessage);
      } else if (jsonRpcMessage is JsonRpcErrorResponse) {
        _handleErrorResponse(jsonRpcMessage);
      }
    } catch (e) {
      _logger.severe('Failed to handle message: $e');
      _sendErrorResponse(
        null,
        McpError(
          code: ErrorCodes.invalidRequest,
          message: 'Invalid request: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles an incoming request.
  Future<void> _handleRequest(JsonRpcRequest request) async {
    if (_requestHandler == null) {
      _sendErrorResponse(
        request.id,
        McpError(
          code: ErrorCodes.methodNotFound,
          message: 'No request handler registered',
        ),
      );
      return;
    }

    try {
      final result = await _requestHandler!(request.method, request.params);
      _sendSuccessResponse(request.id, result);
    } catch (e) {
      if (e is McpException) {
        _sendErrorResponse(
          request.id,
          McpError(
            code: e.code,
            message: e.message,
            data: e.data,
          ),
        );
      } else {
        _sendErrorResponse(
          request.id,
          McpError(
            code: ErrorCodes.internalError,
            message: 'Internal error: ${e.toString()}',
          ),
        );
      }
    }
  }

  /// Handles an incoming notification.
  void _handleNotification(JsonRpcNotification notification) {
    _notificationsController.add(notification);
  }

  /// Handles an incoming success response.
  void _handleSuccessResponse(JsonRpcSuccessResponse response) {
    final completer = _pendingRequests.remove(response.id);
    if (completer != null) {
      completer.complete(response.result);
    } else {
      _logger.warning('Received response for unknown request: ${response.id}');
    }
  }

  /// Handles an incoming error response.
  void _handleErrorResponse(JsonRpcErrorResponse response) {
    final completer = _pendingRequests.remove(response.id);
    if (completer != null) {
      completer.completeError(
        McpException(
          response.error.message,
          response.error.code,
          response.error.data,
        ),
      );
    } else {
      _logger.warning('Received error for unknown request: ${response.id}');
    }
  }

  /// Handles an error from the transport.
  void _handleError(Object error) {
    _logger.severe('Transport error: $error');
    for (final completer in _pendingRequests.values) {
      completer.completeError(
        McpException('Transport error: $error', ErrorCodes.internalError),
      );
    }
    _pendingRequests.clear();
  }

  /// Sends a success response.
  Future<void> _sendSuccessResponse(RequestId id, dynamic result) async {
    final response = JsonRpcSuccessResponse(id: id, result: result);
    await _sendMessage(response);
  }

  /// Sends an error response.
  Future<void> _sendErrorResponse(RequestId? id, McpError error) async {
    final response = JsonRpcErrorResponse(id: id ?? 'null', error: error);
    await _sendMessage(response);
  }

  /// Sends a JSON-RPC message.
  Future<void> _sendMessage(JsonRpcMessage message) async {
    final jsonStr = json.encode(message.toJson());
    await _transport.send(jsonStr);
  }
}
