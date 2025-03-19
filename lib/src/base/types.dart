/// Core type definitions for the Model Context Protocol (MCP).
import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

/// Represents a request ID in the MCP protocol.
/// Can be either a string or an integer.
typedef RequestId = Object;

/// Represents a progress token in the MCP protocol.
/// Can be either a string or an integer.
typedef ProgressToken = Object;

/// Standard logging levels defined by the protocol.
enum LoggingLevel {
  /// Detailed debug information
  debug,

  /// Interesting events
  info,

  /// Normal but significant events
  notice,

  /// Warning conditions
  warning,

  /// Error conditions
  error,

  /// Critical conditions
  critical,

  /// Action must be taken immediately
  alert,

  /// System is unusable
  emergency,
}

/// Information about a client application.
@JsonSerializable()
class ClientInfo {
  /// The name of the client application.
  final String name;

  /// The version of the client application.
  final String version;

  /// Creates a new [ClientInfo] instance.
  ClientInfo({required this.name, required this.version});

  /// Creates a [ClientInfo] from JSON.
  factory ClientInfo.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoFromJson(json);

  /// Converts this [ClientInfo] to JSON.
  Map<String, dynamic> toJson() => _$ClientInfoToJson(this);
}

/// Information about a server application.
@JsonSerializable()
class ServerInfo {
  /// The name of the server application.
  final String name;

  /// The version of the server application.
  final String version;

  /// Creates a new [ServerInfo] instance.
  ServerInfo({required this.name, required this.version});

  /// Creates a [ServerInfo] from JSON.
  factory ServerInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoFromJson(json);

  /// Converts this [ServerInfo] to JSON.
  Map<String, dynamic> toJson() => _$ServerInfoToJson(this);
}

/// Metadata for requests in the MCP protocol.
@JsonSerializable()
class RequestMeta {
  /// A custom request identifier.
  final String? id;

  /// User-provided title for this request.
  final String? title;

  /// User-provided description for this request.
  final String? description;

  /// Creates a new [RequestMeta] instance.
  RequestMeta({this.id, this.title, this.description});

  /// Creates a [RequestMeta] from JSON.
  factory RequestMeta.fromJson(Map<String, dynamic> json) =>
      _$RequestMetaFromJson(json);

  /// Converts this [RequestMeta] to JSON.
  Map<String, dynamic> toJson() => _$RequestMetaToJson(this);
}

/// Base class for all client capabilities.
abstract class ClientCapability {
  /// Converts this capability to JSON.
  Map<String, dynamic> toJson();
}

/// Container for all client capabilities.
@JsonSerializable()
class ClientCapabilities {
  /// The roots capability for working with resource hierarchies.
  final Map<String, dynamic>? roots;

  /// The sampling capability for model output sampling.
  final Map<String, dynamic>? sampling;

  /// Creates a new [ClientCapabilities] instance.
  ClientCapabilities({this.roots, this.sampling});

  /// Creates a [ClientCapabilities] from JSON.
  factory ClientCapabilities.fromJson(Map<String, dynamic> json) =>
      _$ClientCapabilitiesFromJson(json);

  /// Converts this [ClientCapabilities] to JSON.
  Map<String, dynamic> toJson() => _$ClientCapabilitiesToJson(this);
}

/// Base class for all server capabilities.
abstract class ServerCapability {
  /// Converts this capability to JSON.
  Map<String, dynamic> toJson();
}

/// Container for all server capabilities.
@JsonSerializable()
class ServerCapabilities {
  /// The prompts capability for sending prompts to the server.
  final Map<String, dynamic>? prompts;

  /// The resources capability for accessing resources.
  final Map<String, dynamic>? resources;

  /// The tools capability for accessing tools.
  final Map<String, dynamic>? tools;

  /// The logging capability for sending log messages.
  final Map<String, dynamic>? logging;

  /// Creates a new [ServerCapabilities] instance.
  ServerCapabilities({this.prompts, this.resources, this.tools, this.logging});

  /// Creates a [ServerCapabilities] from JSON.
  factory ServerCapabilities.fromJson(Map<String, dynamic> json) =>
      _$ServerCapabilitiesFromJson(json);

  /// Converts this [ServerCapabilities] to JSON.
  Map<String, dynamic> toJson() => _$ServerCapabilitiesToJson(this);
}

/// Represents an URI in the MCP protocol.
@JsonSerializable()
class Uri {
  /// The URI string.
  final String uri;

  /// Creates a new [Uri] instance.
  Uri(this.uri);

  /// Creates a [Uri] from JSON.
  factory Uri.fromJson(Map<String, dynamic> json) => _$UriFromJson(json);

  /// Converts this [Uri] to JSON.
  Map<String, dynamic> toJson() => _$UriToJson(this);
}

/// Base class for all protocol errors.
@JsonSerializable()
class McpError {
  /// The error code.
  final int code;

  /// The error message.
  final String message;

  /// Additional error data.
  final Map<String, dynamic>? data;

  /// Creates a new [McpError] instance.
  McpError({
    required this.code,
    required this.message,
    this.data,
  });

  /// Creates an [McpError] from JSON.
  factory McpError.fromJson(Map<String, dynamic> json) =>
      _$McpErrorFromJson(json);

  /// Converts this [McpError] to JSON.
  Map<String, dynamic> toJson() => _$McpErrorToJson(this);
}

/// Standard error codes in the MCP protocol.
class ErrorCodes {
  /// Parse error.
  static const int parseError = -32700;

  /// Invalid request.
  static const int invalidRequest = -32600;

  /// Method not found.
  static const int methodNotFound = -32601;

  /// Invalid params.
  static const int invalidParams = -32602;

  /// Internal error.
  static const int internalError = -32603;

  /// Server error.
  static const int serverError = -32000;

  /// Request cancelled.
  static const int requestCancelled = -32800;

  /// Content too large.
  static const int contentTooLarge = -32801;

  /// Capability not supported.
  static const int capabilityNotSupported = -32802;
}
