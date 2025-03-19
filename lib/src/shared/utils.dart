/// Utility functions for the Model Context Protocol.
import 'dart:convert';

/// Encodes an object to JSON, following MCP conventions.
String encodeJson(dynamic object) {
  return json.encode(object, toEncodable: _toEncodable);
}

/// Custom JSON encoding function for handling types not natively supported by dart:convert.
dynamic _toEncodable(dynamic object) {
  if (object is DateTime) {
    return object.toIso8601String();
  } else if (object is RegExp) {
    return object.pattern;
  } else if (object is Uri) {
    return object.toString();
  } else if (object is BigInt) {
    return object.toString();
  } else {
    return object;
  }
}

/// Validates that an object has all required fields.
///
/// Throws [ArgumentError] if any required field is missing.
void validateRequiredFields(
    Map<String, dynamic> object, List<String> requiredFields) {
  final missing = <String>[];

  for (final field in requiredFields) {
    if (!object.containsKey(field) || object[field] == null) {
      missing.add(field);
    }
  }

  if (missing.isNotEmpty) {
    throw ArgumentError('Missing required fields: ${missing.join(', ')}');
  }
}

/// Validates that a value is one of the allowed values.
///
/// Throws [ArgumentError] if the value is not allowed.
void validateEnum<T>(T value, List<T> allowedValues, String fieldName) {
  if (!allowedValues.contains(value)) {
    throw ArgumentError(
      'Invalid value for $fieldName: $value. '
      'Allowed values: ${allowedValues.join(', ')}',
    );
  }
}

/// Validates that a string matches a pattern.
///
/// Throws [ArgumentError] if the string doesn't match the pattern.
void validatePattern(String value, RegExp pattern, String fieldName) {
  if (!pattern.hasMatch(value)) {
    throw ArgumentError(
      'Invalid value for $fieldName: $value. '
      'Must match pattern: ${pattern.pattern}',
    );
  }
}

/// Validates that a number is within a range.
///
/// Throws [ArgumentError] if the number is outside the range.
void validateRange(num value, num min, num max, String fieldName) {
  if (value < min || value > max) {
    throw ArgumentError(
      'Invalid value for $fieldName: $value. '
      'Must be between $min and $max',
    );
  }
}

/// Converts a string to a URI, validating that it's a valid URI.
///
/// Throws [ArgumentError] if the string is not a valid URI.
Uri stringToUri(String uriString) {
  try {
    return Uri.parse(uriString);
  } catch (e) {
    throw ArgumentError('Invalid URI: $uriString');
  }
}

/// Ensures that a map's keys and values are of the correct types.
///
/// Throws [ArgumentError] if any key or value is of the wrong type.
void validateMapTypes<K, V>(Map<dynamic, dynamic> map, String fieldName) {
  for (final entry in map.entries) {
    if (entry.key is! K) {
      throw ArgumentError(
        'Invalid key type for $fieldName: ${entry.key.runtimeType}. '
        'Expected: $K',
      );
    }

    if (entry.value is! V) {
      throw ArgumentError(
        'Invalid value type for $fieldName: ${entry.value.runtimeType}. '
        'Expected: $V',
      );
    }
  }
}

/// Ensures that all elements in a list are of the correct type.
///
/// Throws [ArgumentError] if any element is of the wrong type.
void validateListTypes<T>(List<dynamic> list, String fieldName) {
  for (int i = 0; i < list.length; i++) {
    if (list[i] is! T) {
      throw ArgumentError(
        'Invalid element type at index $i for $fieldName: ${list[i].runtimeType}. '
        'Expected: $T',
      );
    }
  }
}
