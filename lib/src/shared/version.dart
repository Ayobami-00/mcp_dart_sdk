/// Version information for the MCP Dart SDK.

/// The current version of the MCP Dart SDK.
const String packageVersion = '0.1.0';

/// The minimum MCP protocol version supported by this SDK.
const String minProtocolVersion = '0.1.0';

/// The maximum MCP protocol version supported by this SDK.
const String maxProtocolVersion = '0.1.0';

/// Checks if a protocol version is supported by this SDK.
///
/// Returns true if the version is supported, false otherwise.
bool isProtocolVersionSupported(String version) {
  final minVersion = _parseVersion(minProtocolVersion);
  final maxVersion = _parseVersion(maxProtocolVersion);
  final targetVersion = _parseVersion(version);

  return _compareVersions(targetVersion, minVersion) >= 0 &&
      _compareVersions(targetVersion, maxVersion) <= 0;
}

/// Parses a semantic version string into a list of integers.
List<int> _parseVersion(String version) {
  return version
      .split('.')
      .map((part) => int.parse(part.split('-')[0]))
      .toList();
}

/// Compares two version lists.
///
/// Returns:
/// - A positive value if version1 is greater than version2
/// - Zero if version1 is equal to version2
/// - A negative value if version1 is less than version2
int _compareVersions(List<int> version1, List<int> version2) {
  final minLength =
      version1.length < version2.length ? version1.length : version2.length;

  for (int i = 0; i < minLength; i++) {
    final diff = version1[i] - version2[i];
    if (diff != 0) {
      return diff;
    }
  }

  return version1.length - version2.length;
}
