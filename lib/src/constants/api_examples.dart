/// Canonical API examples shown in the guide and questionnaire.
class ApiExamples {
  static const queryParams = '''
{
  "page": 1,
  "per_page": 20,
  "search": "test"
}''';

  static const requestBody = '''
{
  "name": "Test Organization",
  "phone": "+18687687966"
}''';

  static const baseResponse = '''
{
  "status": true,
  "message": "OK"
}''';

  static const dataListItem = '''
[
  {
    "id": 270173,
    "name": "Test",
    "email": "test@test.com",
    "phone": "+1 111 111 1111",
    "industry_id": 33,
    "industry": {
      "id": 33,
      "name": "Restaurants",
      "color": "#d519eb"
    },
    "created_at": "2026-06-10T13:54:02.000000Z"
  }
]''';

  static const paginationObject = '''
{
  "total": 129,
  "per_page": 20,
  "current_page": 1,
  "last_page": 7
}''';

  static const dataSingleObject = '''
{
  "id": 1,
  "valid_number": false
}''';
}
