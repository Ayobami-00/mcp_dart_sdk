/// Sampling capability for the Model Context Protocol.
///
/// The sampling capability allows the client to get intermediate model outputs.
import 'package:json_annotation/json_annotation.dart';

import '../../base/types.dart';
import '../../shared/exceptions.dart';
import '../client.dart';

part 'sampling.g.dart';

/// Client capability for sampling model outputs.
@JsonSerializable()
class SamplingCapability implements ClientCapability {
  /// Creates a new [SamplingCapability] instance.
  SamplingCapability();

  /// Creates a [SamplingCapability] from JSON.
  factory SamplingCapability.fromJson(Map<String, dynamic> json) =>
      _$SamplingCapabilityFromJson(json);

  /// Converts this [SamplingCapability] to JSON.
  @override
  Map<String, dynamic> toJson() => _$SamplingCapabilityToJson(this);
}

/// Parameters for the 'sampling/start' request.
@JsonSerializable()
class SamplingStartParams {
  /// The request ID of the prompt request to sample from.
  final String promptRequestId;

  /// The interval in milliseconds between sampling events.
  final int? interval;

  /// Creates a new [SamplingStartParams] instance.
  SamplingStartParams({
    required this.promptRequestId,
    this.interval,
  });

  /// Creates a [SamplingStartParams] from JSON.
  factory SamplingStartParams.fromJson(Map<String, dynamic> json) =>
      _$SamplingStartParamsFromJson(json);

  /// Converts this [SamplingStartParams] to JSON.
  Map<String, dynamic> toJson() => _$SamplingStartParamsToJson(this);
}

/// Result of the 'sampling/start' request.
@JsonSerializable()
class SamplingStartResult {
  /// The ID of the sampling session.
  final String id;

  /// Creates a new [SamplingStartResult] instance.
  SamplingStartResult({required this.id});

  /// Creates a [SamplingStartResult] from JSON.
  factory SamplingStartResult.fromJson(Map<String, dynamic> json) =>
      _$SamplingStartResultFromJson(json);

  /// Converts this [SamplingStartResult] to JSON.
  Map<String, dynamic> toJson() => _$SamplingStartResultToJson(this);
}

/// Parameters for the 'sampling/stop' request.
@JsonSerializable()
class SamplingStopParams {
  /// The ID of the sampling session to stop.
  final String id;

  /// Creates a new [SamplingStopParams] instance.
  SamplingStopParams({required this.id});

  /// Creates a [SamplingStopParams] from JSON.
  factory SamplingStopParams.fromJson(Map<String, dynamic> json) =>
      _$SamplingStopParamsFromJson(json);

  /// Converts this [SamplingStopParams] to JSON.
  Map<String, dynamic> toJson() => _$SamplingStopParamsToJson(this);
}

/// Result of the 'sampling/stop' request.
@JsonSerializable()
class SamplingStopResult {
  /// Creates a new [SamplingStopResult] instance.
  SamplingStopResult();

  /// Creates a [SamplingStopResult] from JSON.
  factory SamplingStopResult.fromJson(Map<String, dynamic> json) =>
      _$SamplingStopResultFromJson(json);

  /// Converts this [SamplingStopResult] to JSON.
  Map<String, dynamic> toJson() => _$SamplingStopResultToJson(this);
}

/// Parameters for the 'sampling/event' notification.
@JsonSerializable()
class SamplingEventParams {
  /// The ID of the sampling session.
  final String id;

  /// The current model output.
  final String output;

  /// Creates a new [SamplingEventParams] instance.
  SamplingEventParams({
    required this.id,
    required this.output,
  });

  /// Creates a [SamplingEventParams] from JSON.
  factory SamplingEventParams.fromJson(Map<String, dynamic> json) =>
      _$SamplingEventParamsFromJson(json);

  /// Converts this [SamplingEventParams] to JSON.
  Map<String, dynamic> toJson() => _$SamplingEventParamsToJson(this);
}

/// A handler for sampling events.
typedef SamplingEventHandler = void Function(String id, String output);

/// Extension methods for the McpClient to work with sampling.
extension SamplingClientExtension on McpClient {
  /// Checks if the sampling capability is supported.
  bool get supportsSampling => isCapabilitySupported('sampling');

  /// Starts sampling a prompt request.
  ///
  /// Throws [CapabilityNotSupportedException] if the sampling capability is not supported.
  Future<String> startSampling({
    required String promptRequestId,
    int? interval,
    SamplingEventHandler? onSample,
  }) async {
    if (!supportsSampling) {
      throw CapabilityNotSupportedException('sampling');
    }

    // Register the event handler
    if (onSample != null) {
      registerSamplingEventHandler(onSample);
    }

    final params = SamplingStartParams(
      promptRequestId: promptRequestId,
      interval: interval,
    );

    final result = await sendRequest('sampling/start', params.toJson());
    final startResult =
        SamplingStartResult.fromJson(result as Map<String, dynamic>);

    return startResult.id;
  }

  /// Stops sampling a prompt request.
  ///
  /// Throws [CapabilityNotSupportedException] if the sampling capability is not supported.
  Future<void> stopSampling(String id) async {
    if (!supportsSampling) {
      throw CapabilityNotSupportedException('sampling');
    }

    final params = SamplingStopParams(id: id);

    await sendRequest('sampling/stop', params.toJson());
  }

  /// Registers a handler for sampling events.
  void registerSamplingEventHandler(SamplingEventHandler handler) {
    // We need to listen to notifications from the session
    // This assumes the session exposes its notifications stream
    if (!supportsSampling) {
      throw CapabilityNotSupportedException('sampling');
    }

    // Get the session from the client
    final session = this.session;
    if (session == null) {
      throw StateError('Not connected to a server');
    }

    // Listen for sampling events
    session.notifications.listen((notification) {
      if (notification.method == 'sampling/event') {
        final params = SamplingEventParams.fromJson(
            notification.params as Map<String, dynamic>);

        handler(params.id, params.output);
      }
    });
  }
}
