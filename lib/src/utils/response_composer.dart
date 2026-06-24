import 'dart:convert';

import '../constants/api_examples.dart';
import '../constants/pagination_keys.dart';

class ResponseParts {
  final String baseResponseExample;
  final String dataExample;
  final String paginationExample;
  final String paginationKey;

  const ResponseParts({
    this.baseResponseExample = '',
    this.dataExample = '',
    this.paginationExample = '',
    this.paginationKey = PaginationKeys.defaultKey,
  });
}

class ResponseComposer {
  static String get defaultBaseResponse => ApiExamples.baseResponse.trim();

  static String get defaultDataExample => ApiExamples.dataListItem.trim();

  static String get defaultPaginationExample =>
      ApiExamples.paginationObject.trim();

  static ResponseParts split(String fullResponse) {
    if (fullResponse.trim().isEmpty) {
      return const ResponseParts();
    }

    try {
      final decoded = jsonDecode(fullResponse);
      if (decoded is! Map) {
        return ResponseParts(dataExample: fullResponse.trim());
      }

      final map = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      var data = map['data'];
      final paginationKey = PaginationKeys.detectFromMap(map);
      var pagination = paginationKey == null ? null : map[paginationKey];

      final base = Map<String, dynamic>.from(map)
        ..remove('data');
      for (final key in PaginationKeys.all) {
        base.remove(key);
      }

      if (data is Map) {
        final dataMap = data.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final nestedKey = PaginationKeys.detectFromMap(dataMap);
        if (nestedKey != null) {
          pagination ??= dataMap[nestedKey];
          dataMap.remove(nestedKey);
          data = dataMap.containsKey('data') ? dataMap['data'] : dataMap;
        }
      }

      return ResponseParts(
        baseResponseExample: _encodeJson(base),
        dataExample: data == null ? '' : _encodeJson(data),
        paginationExample: pagination == null ? '' : _encodeJson(pagination),
        paginationKey: paginationKey ?? PaginationKeys.defaultKey,
      );
    } catch (_) {
      return ResponseParts(dataExample: fullResponse.trim());
    }
  }

  static String compose({
    required String baseResponseExample,
    required String dataExample,
    String paginationExample = '',
    bool includePagination = false,
    String paginationKey = PaginationKeys.defaultKey,
  }) {
    final base = _parseObject(
      baseResponseExample,
      fallback: const {'status': true, 'message': 'OK'},
    );
    final composed = Map<String, dynamic>.from(base);

    if (dataExample.trim().isNotEmpty) {
      composed['data'] = _parseJson(
        dataExample,
        fallback: const [],
      );
    }

    if (includePagination && paginationExample.trim().isNotEmpty) {
      composed[paginationKey] = _parseObject(
        paginationExample,
        fallback: const {},
      );
    }

    return const JsonEncoder.withIndent('  ').convert(composed);
  }

  static Map<String, dynamic> _parseObject(
    String raw, {
    required Map<String, dynamic> fallback,
  }) {
    if (raw.trim().isEmpty) return Map<String, dynamic>.from(fallback);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {}

    return Map<String, dynamic>.from(fallback);
  }

  static dynamic _parseJson(String raw, {required dynamic fallback}) {
    if (raw.trim().isEmpty) return fallback;

    try {
      return jsonDecode(raw);
    } catch (_) {
      return fallback;
    }
  }

  static String _encodeJson(dynamic value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
