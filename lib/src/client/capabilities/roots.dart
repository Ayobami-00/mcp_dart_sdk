/// Roots capability for the Model Context Protocol.
///
/// The roots capability allows the client to navigate hierarchical resources.
import 'package:json_annotation/json_annotation.dart';

import '../../base/types.dart';
import '../../shared/exceptions.dart';
import '../client.dart';

part 'roots.g.dart';

/// Client capability for working with resource hierarchies.
@JsonSerializable()
class RootsCapability implements ClientCapability {
  /// Creates a new [RootsCapability] instance.
  RootsCapability();

  /// Creates a [RootsCapability] from JSON.
  factory RootsCapability.fromJson(Map<String, dynamic> json) =>
      _$RootsCapabilityFromJson(json);

  /// Converts this [RootsCapability] to JSON.
  @override
  Map<String, dynamic> toJson() => _$RootsCapabilityToJson(this);
}

/// Response for the 'roots/list' request.
@JsonSerializable()
class RootsListResult {
  /// The root URIs available.
  final List<String> roots;

  /// Creates a new [RootsListResult] instance.
  RootsListResult({required this.roots});

  /// Creates a [RootsListResult] from JSON.
  factory RootsListResult.fromJson(Map<String, dynamic> json) =>
      _$RootsListResultFromJson(json);

  /// Converts this [RootsListResult] to JSON.
  Map<String, dynamic> toJson() => _$RootsListResultToJson(this);
}

/// Extension methods for the McpClient to work with roots.
extension RootsClientExtension on McpClient {
  /// Checks if the roots capability is supported.
  bool get supportsRoots => isCapabilitySupported('roots');

  /// Lists all available roots.
  ///
  /// Throws [CapabilityNotSupportedException] if the roots capability is not supported.
  Future<List<String>> listRoots() async {
    if (!supportsRoots) {
      throw CapabilityNotSupportedException('roots');
    }

    final result = await sendRequest('roots/list');
    final listResult = RootsListResult.fromJson(result as Map<String, dynamic>);

    return listResult.roots;
  }

  /// Gets the children of a root.
  ///
  /// Throws [CapabilityNotSupportedException] if the roots capability is not supported.
  Future<List<String>> getRootChildren(String rootUri) async {
    if (!supportsRoots) {
      throw CapabilityNotSupportedException('roots');
    }

    final result = await sendRequest('roots/children', {
      'uri': rootUri,
    });

    return (result['children'] as List<dynamic>)
        .map((uri) => uri as String)
        .toList();
  }

  /// Gets metadata for a root.
  ///
  /// Throws [CapabilityNotSupportedException] if the roots capability is not supported.
  Future<Map<String, dynamic>> getRootMetadata(String rootUri) async {
    if (!supportsRoots) {
      throw CapabilityNotSupportedException('roots');
    }

    final result = await sendRequest('roots/metadata', {
      'uri': rootUri,
    });

    return result['metadata'] as Map<String, dynamic>;
  }
}
