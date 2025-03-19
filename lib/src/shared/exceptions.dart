/// Exceptions used in the Model Context Protocol.
import '../base/types.dart';

/// Base class for all MCP exceptions.
class McpException implements Exception {
  /// The error message.
  final String message;

  /// The error code.
  final int code;

  /// Additional error data.
  final Map<String, dynamic>? data;

  /// Creates a new [McpException] instance.
  McpException(this.message, this.code, [this.data]);

  @override
  String toString() {
    return 'McpException: $message (code $code)${data != null ? ', data: $data' : ''}';
  }
}

/// Exception thrown when a capability is not supported.
class CapabilityNotSupportedException extends McpException {
  /// Creates a new [CapabilityNotSupportedException] instance.
  CapabilityNotSupportedException(String capability)
      : super(
          'Capability not supported: $capability',
          ErrorCodes.capabilityNotSupported,
          {'capability': capability},
        );
}

/// Exception thrown when a transport error occurs.
class TransportException extends McpException {
  /// Creates a new [TransportException] instance.
  TransportException(String message) : super(message, ErrorCodes.internalError);
}

/// Exception thrown when a request is cancelled.
class RequestCancelledException extends McpException {
  /// Creates a new [RequestCancelledException] instance.
  RequestCancelledException()
      : super('Request cancelled', ErrorCodes.requestCancelled);
}

/// Exception thrown when the content is too large.
class ContentTooLargeException extends McpException {
  /// Creates a new [ContentTooLargeException] instance.
  ContentTooLargeException(String message)
      : super(message, ErrorCodes.contentTooLarge);
}

/// Exception thrown when a method is not found.
class MethodNotFoundException extends McpException {
  /// Creates a new [MethodNotFoundException] instance.
  MethodNotFoundException(String method)
      : super(
          'Method not found: $method',
          ErrorCodes.methodNotFound,
          {'method': method},
        );
}

/// Exception thrown when parameters are invalid.
class InvalidParamsException extends McpException {
  /// Creates a new [InvalidParamsException] instance.
  InvalidParamsException(String message)
      : super(message, ErrorCodes.invalidParams);
}

/// Exception thrown when a request is invalid.
class InvalidRequestException extends McpException {
  /// Creates a new [InvalidRequestException] instance.
  InvalidRequestException(String message)
      : super(message, ErrorCodes.invalidRequest);
}

/// Exception thrown when there is an internal error.
class InternalErrorException extends McpException {
  /// Creates a new [InternalErrorException] instance.
  InternalErrorException(String message)
      : super(message, ErrorCodes.internalError);
}
