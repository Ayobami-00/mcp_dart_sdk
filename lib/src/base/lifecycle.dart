/// Session lifecycle management for the Model Context Protocol.
import 'package:json_annotation/json_annotation.dart';
import 'types.dart';

part 'lifecycle.g.dart';

/// Parameters for the 'initialize' request.
@JsonSerializable()
class InitializeParams {
  /// Client information.
  final ClientInfo clientInfo;

  /// Capabilities the client supports.
  final ClientCapabilities capabilities;

  /// Creates a new [InitializeParams] instance.
  InitializeParams({
    required this.clientInfo,
    required this.capabilities,
  });

  /// Creates an [InitializeParams] from JSON.
  factory InitializeParams.fromJson(Map<String, dynamic> json) =>
      _$InitializeParamsFromJson(json);

  /// Converts this [InitializeParams] to JSON.
  Map<String, dynamic> toJson() => _$InitializeParamsToJson(this);
}

/// Result of the 'initialize' request.
@JsonSerializable()
class InitializeResult {
  /// Server information.
  final ServerInfo serverInfo;

  /// Capabilities the server supports.
  final ServerCapabilities capabilities;

  /// Creates a new [InitializeResult] instance.
  InitializeResult({
    required this.serverInfo,
    required this.capabilities,
  });

  /// Creates an [InitializeResult] from JSON.
  factory InitializeResult.fromJson(Map<String, dynamic> json) =>
      _$InitializeResultFromJson(json);

  /// Converts this [InitializeResult] to JSON.
  Map<String, dynamic> toJson() => _$InitializeResultToJson(this);
}

/// Parameters for the 'shutdown' request.
@JsonSerializable()
class ShutdownParams {
  /// Creates a new [ShutdownParams] instance.
  ShutdownParams();

  /// Creates a [ShutdownParams] from JSON.
  factory ShutdownParams.fromJson(Map<String, dynamic> json) =>
      _$ShutdownParamsFromJson(json);

  /// Converts this [ShutdownParams] to JSON.
  Map<String, dynamic> toJson() => _$ShutdownParamsToJson(this);
}

/// Result of the 'shutdown' request.
@JsonSerializable()
class ShutdownResult {
  /// Creates a new [ShutdownResult] instance.
  ShutdownResult();

  /// Creates a [ShutdownResult] from JSON.
  factory ShutdownResult.fromJson(Map<String, dynamic> json) =>
      _$ShutdownResultFromJson(json);

  /// Converts this [ShutdownResult] to JSON.
  Map<String, dynamic> toJson() => _$ShutdownResultToJson(this);
}

/// Parameters for the 'exit' notification.
@JsonSerializable()
class ExitParams {
  /// Creates a new [ExitParams] instance.
  ExitParams();

  /// Creates an [ExitParams] from JSON.
  factory ExitParams.fromJson(Map<String, dynamic> json) =>
      _$ExitParamsFromJson(json);

  /// Converts this [ExitParams] to JSON.
  Map<String, dynamic> toJson() => _$ExitParamsToJson(this);
}

/// Session state for the MCP protocol.
enum SessionState {
  /// The session has not been initialized.
  uninitialized,

  /// The session has been initialized.
  initialized,

  /// The session is shutting down.
  shuttingDown,

  /// The session has been shut down.
  shutdown,

  /// The session has exited.
  exited,
}

/// Lifecycle method names in the MCP protocol.
class LifecycleMethods {
  /// The initialize method.
  static const String initialize = 'initialize';

  /// The shutdown method.
  static const String shutdown = 'shutdown';

  /// The exit notification.
  static const String exit = 'exit';
}
