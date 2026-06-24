import 'package:test/test.dart';
import 'package:uncle_bob/src/utils/pagination_detector.dart';

void main() {
  group('PaginationDetector', () {
    test('detects root pagination object', () {
      const response = '''
{
  "status": true,
  "data": [],
  "pagination": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 40
  }
}
''';

      expect(PaginationDetector.detectFromResponse(response), isTrue);
      expect(
        PaginationDetector.extractFromResponse(response),
        contains('current_page'),
      );
      expect(
        PaginationDetector.detectKeyFromResponse(response),
        equals('pagination'),
      );
    });

    test('detects paginationData key (SendBat / Kore style)', () {
      const response = '''
{
  "status": true,
  "data": [],
  "paginationData": {
    "current_page": 1,
    "last_page": 7,
    "per_page": 20,
    "total": 129
  }
}
''';

      expect(PaginationDetector.detectFromResponse(response), isTrue);
      expect(
        PaginationDetector.detectKeyFromResponse(response),
        equals('paginationData'),
      );
    });

    test('detects nested data.pagination', () {
      const response = '''
{
  "status": true,
  "data": {
    "data": [],
    "pagination": {
      "current_page": 2,
      "last_page": 5
    }
  }
}
''';

      expect(PaginationDetector.detectFromResponse(response), isTrue);
    });

    test('returns false for non paginated response', () {
      const response = '{"status": true, "data": {"id": 1, "name": "x"}}';
      expect(PaginationDetector.detectFromResponse(response), isFalse);
    });
  });
}
