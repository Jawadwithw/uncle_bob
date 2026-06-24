import 'dart:convert';

import '../constants/pagination_keys.dart';

class PaginationDetector {
  static bool looksLikePaginationMap(Map<dynamic, dynamic> value) {
    return PaginationKeys.looksLikePaginationMap(value);
  }

  static bool detectFromResponse(String responseExample) {
    if (responseExample.trim().isEmpty) return false;

    try {
      final decoded = jsonDecode(responseExample);
      if (decoded is! Map) return false;

      final map = decoded.map((key, value) => MapEntry(key.toString(), value));

      if (PaginationKeys.detectFromMap(map) != null) {
        return true;
      }

      if (map['data'] is Map) {
        final data = (map['data'] as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (PaginationKeys.detectFromMap(data) != null) {
          return true;
        }
      }

      return looksLikePaginationMap(map);
    } catch (_) {
      return false;
    }
  }

  static String extractFromResponse(String responseExample) {
    if (responseExample.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(responseExample);
      if (decoded is! Map) return '';

      final map = decoded.map((key, value) => MapEntry(key.toString(), value));

      final rootKey = PaginationKeys.detectFromMap(map);
      if (rootKey != null && map[rootKey] is Map) {
        return const JsonEncoder.withIndent('  ').convert(map[rootKey]);
      }

      if (map['data'] is Map) {
        final data = (map['data'] as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final nestedKey = PaginationKeys.detectFromMap(data);
        if (nestedKey != null && data[nestedKey] is Map) {
          return const JsonEncoder.withIndent('  ').convert(data[nestedKey]);
        }
      }

      if (looksLikePaginationMap(map)) {
        return const JsonEncoder.withIndent('  ').convert(map);
      }
    } catch (_) {
      return '';
    }

    return '';
  }

  static String detectKeyFromResponse(String responseExample) {
    if (responseExample.trim().isEmpty) return PaginationKeys.defaultKey;

    try {
      final decoded = jsonDecode(responseExample);
      if (decoded is! Map) return PaginationKeys.defaultKey;

      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      return PaginationKeys.detectFromMap(map) ?? PaginationKeys.defaultKey;
    } catch (_) {
      return PaginationKeys.defaultKey;
    }
  }
}
