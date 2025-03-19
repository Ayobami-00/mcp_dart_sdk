/// Request context handling for the Model Context Protocol.
import '../base/session.dart';
import '../base/types.dart';

/// Base class for all request contexts.
///
/// A request context is passed to request handlers and contains
/// information about the request, such as the request ID, metadata,
/// and the session that received the request.
///
/// The type parameters allow for type-safe handling of different
/// session types and lifespan contexts.
class RequestContext<SessionT extends BaseSession, LifespanContextT> {
  /// The ID of the request.
  final RequestId requestId;

  /// Optional metadata for the request.
  final RequestMeta? meta;

  /// The session that received the request.
  final SessionT session;

  /// Context that is shared across the lifespan of this request.
  final LifespanContextT lifespanContext;

  /// Creates a new [RequestContext] instance.
  RequestContext({
    required this.requestId,
    this.meta,
    required this.session,
    required this.lifespanContext,
  });
}

/// A factory for creating request contexts.
///
/// This is used by the session implementation to create request contexts
/// for different types of requests.
class RequestContextFactory<SessionT extends BaseSession, LifespanContextT> {
  /// Function that creates a lifespan context.
  final LifespanContextT Function() _createLifespanContext;

  /// Creates a new [RequestContextFactory] instance.
  RequestContextFactory({
    required LifespanContextT Function() createLifespanContext,
  }) : _createLifespanContext = createLifespanContext;

  /// Creates a new request context.
  RequestContext<SessionT, LifespanContextT> createContext({
    required RequestId requestId,
    RequestMeta? meta,
    required SessionT session,
  }) {
    return RequestContext<SessionT, LifespanContextT>(
      requestId: requestId,
      meta: meta,
      session: session,
      lifespanContext: _createLifespanContext(),
    );
  }
}
