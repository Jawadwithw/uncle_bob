/// Converts a feature name to `snake_case` (e.g. `user_profile`).
String toSnakeCase(String input) {
  final normalized = input.trim().replaceAll(RegExp(r'[\s\-]+'), '_');
  return normalized
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      )
      .replaceAll(RegExp(r'^_'), '')
      .replaceAll(RegExp(r'_+'), '_')
      .toLowerCase();
}

/// Converts a feature name to `PascalCase` (e.g. `UserProfile`).
String toPascalCase(String input) {
  final snake = toSnakeCase(input);
  return snake
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

/// Converts a feature name to `camelCase` (e.g. `userProfile`).
String toCamelCase(String input) {
  final pascal = toPascalCase(input);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}
