/// JSON-RPC 2.0 message types for the Model Context Protocol.
import 'package:json_annotation/json_annotation.dart';
import 'types.dart';

part 'json_rpc.g.dart';

/// Base class for all JSON-RPC messages.
abstract class JsonRpcMessage {
  /// The JSON-RPC version, always "2.0".
  final String jsonrpc = "2.0";

  /// Converts this message to a JSON map.
  Map<String, dynamic> toJson();
}

/// A JSON-RPC request message.
@JsonSerializable()
class JsonRpcRequest extends JsonRpcMessage {
  /// The request ID.
  final RequestId id;

  /// The method to call.
  final String method;

  /// The method parameters.
  final dynamic params;

  /// Creates a new [JsonRpcRequest] instance.
  JsonRpcRequest({
    required this.id,
    required this.method,
    this.params,
  });

  /// Creates a [JsonRpcRequest] from JSON.
  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcRequestFromJson(json);

  /// Converts this [JsonRpcRequest] to JSON.
  @override
  Map<String, dynamic> toJson() => _$JsonRpcRequestToJson(this);
}

/// A JSON-RPC notification message.
@JsonSerializable()
class JsonRpcNotification extends JsonRpcMessage {
  /// The method name.
  final String method;

  /// The method parameters.
  final dynamic params;

  /// Creates a new [JsonRpcNotification] instance.
  JsonRpcNotification({
    required this.method,
    this.params,
  });

  /// Creates a [JsonRpcNotification] from JSON.
  factory JsonRpcNotification.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcNotificationFromJson(json);

  /// Converts this [JsonRpcNotification] to JSON.
  @override
  Map<String, dynamic> toJson() => _$JsonRpcNotificationToJson(this);
}

/// A JSON-RPC success response message.
@JsonSerializable()
class JsonRpcSuccessResponse extends JsonRpcMessage {
  /// The request ID this response is for.
  final RequestId id;

  /// The result of the request.
  final dynamic result;

  /// Creates a new [JsonRpcSuccessResponse] instance.
  JsonRpcSuccessResponse({
    required this.id,
    required this.result,
  });

  /// Creates a [JsonRpcSuccessResponse] from JSON.
  factory JsonRpcSuccessResponse.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcSuccessResponseFromJson(json);

  /// Converts this [JsonRpcSuccessResponse] to JSON.
  @override
  Map<String, dynamic> toJson() => _$JsonRpcSuccessResponseToJson(this);
}

/// A JSON-RPC error response message.
@JsonSerializable()
class JsonRpcErrorResponse extends JsonRpcMessage {
  /// The request ID this response is for.
  final RequestId id;

  /// The error details.
  final McpError error;

  /// Creates a new [JsonRpcErrorResponse] instance.
  JsonRpcErrorResponse({
    required this.id,
    required this.error,
  });

  /// Creates a [JsonRpcErrorResponse] from JSON.
  factory JsonRpcErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcErrorResponseFromJson(json);

  /// Converts this [JsonRpcErrorResponse] to JSON.
  @override
  Map<String, dynamic> toJson() => _$JsonRpcErrorResponseToJson(this);
}

/// Factory methods for creating JSON-RPC messages.
class JsonRpcMessageFactory {
  /// Creates a JSON-RPC message from a JSON map.
  static JsonRpcMessage fromJson(Map<String, dynamic> json) {
    if (json.containsKey('method')) {
      if (json.containsKey('id')) {
        return JsonRpcRequest.fromJson(json);
      } else {
        return JsonRpcNotification.fromJson(json);
      }
    } else if (json.containsKey('result')) {
      return JsonRpcSuccessResponse.fromJson(json);
    } else if (json.containsKey('error')) {
      return JsonRpcErrorResponse.fromJson(json);
    } else {
      throw FormatException('Invalid JSON-RPC message: $json');
    }
  }
}
