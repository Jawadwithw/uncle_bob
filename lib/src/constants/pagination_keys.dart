/// JSON keys used for pagination metadata in API responses.
class PaginationKeys {
  static const paginationData = 'paginationData';
  static const pagination = 'pagination';

  static const defaultKey = paginationData;

  static const all = [paginationData, pagination];

  static const _paginationFieldKeys = {
    'current_page',
    'last_page',
    'per_page',
    'total',
    'total_count',
    'page',
  };

  static bool looksLikePaginationMap(Map<dynamic, dynamic> value) {
    final keys = value.keys.map((key) => key.toString()).toSet();
    return keys.intersection(_paginationFieldKeys).isNotEmpty;
  }

  static String? detectFromMap(Map<dynamic, dynamic> map) {
    for (final key in all) {
      final value = map[key];
      if (value is Map && looksLikePaginationMap(value)) {
        return key;
      }
    }
    return null;
  }
}
