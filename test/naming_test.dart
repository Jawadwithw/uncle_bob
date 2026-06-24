import 'package:test/test.dart';
import 'package:uncle_bob/src/naming.dart';

void main() {
  group('naming', () {
    test('snake case', () {
      expect(toSnakeCase('userProfile'), 'user_profile');
      expect(toSnakeCase('settings'), 'settings');
    });

    test('pascal case', () {
      expect(toPascalCase('user_profile'), 'UserProfile');
      expect(toPascalCase('settings'), 'Settings');
    });
  });
}
