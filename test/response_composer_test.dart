import 'package:test/test.dart';
import 'package:uncle_bob/src/constants/pagination_keys.dart';
import 'package:uncle_bob/src/utils/response_composer.dart';

void main() {
  group('ResponseComposer', () {
    test('splits full response with pagination key', () {
      const full = '''
{
  "status": true,
  "message": "OK",
  "data": [{"id": 1, "name": "Example"}],
  "pagination": {
    "current_page": 1,
    "last_page": 2,
    "per_page": 15,
    "total": 20
  }
}
''';

      final parts = ResponseComposer.split(full);

      expect(parts.baseResponseExample, contains('"status": true'));
      expect(parts.baseResponseExample, isNot(contains('"data"')));
      expect(parts.dataExample, contains('"name": "Example"'));
      expect(parts.paginationExample, contains('current_page'));
      expect(parts.paginationKey, equals(PaginationKeys.pagination));
    });

    test('splits paginationData key', () {
      const full = '''
{
  "status": true,
  "message": "OK",
  "data": [{"id": 270173, "name": "Test"}],
  "paginationData": {
    "total": 129,
    "per_page": 20,
    "current_page": 1,
    "last_page": 7
  }
}
''';

      final parts = ResponseComposer.split(full);

      expect(parts.paginationKey, equals(PaginationKeys.paginationData));
      expect(parts.paginationExample, contains('"total": 129'));
    });

    test('composes parts back into full response', () {
      final composed = ResponseComposer.compose(
        baseResponseExample: '{"status": true, "message": "OK"}',
        dataExample: '[{"id": 1, "name": "Example"}]',
        paginationExample:
            '{"current_page": 1, "last_page": 2, "per_page": 15, "total": 20}',
        includePagination: true,
        paginationKey: PaginationKeys.paginationData,
      );

      expect(composed, contains('"status": true'));
      expect(composed, contains('"data"'));
      expect(composed, contains('"paginationData"'));
      expect(composed, isNot(contains('"pagination"')));
    });

    test('compose omits pagination when not requested', () {
      final composed = ResponseComposer.compose(
        baseResponseExample: '{"status": true, "message": "OK"}',
        dataExample: '[{"id": 1}]',
        paginationExample:
            '{"current_page": 1, "last_page": 2, "per_page": 15, "total": 20}',
        includePagination: false,
      );

      expect(composed, isNot(contains('"pagination"')));
      expect(composed, isNot(contains('"paginationData"')));
    });
  });
}
