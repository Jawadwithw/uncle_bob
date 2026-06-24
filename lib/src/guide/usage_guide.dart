import 'dart:io';

import '../constants/api_examples.dart';

/// Step-by-step usage instructions printed to the terminal.
class UsageGuide {
  static void printFull() {
    stdout.writeln('''
uncle_bob — step-by-step

1) Install (once)
   dart pub global activate --source path /path/to/uncle_bob

2) Go to your Flutter project
   cd my_flutter_app

3) Bootstrap core layers (once per project)
   uncle_bob init

4) Add dependencies to pubspec.yaml (see README), then run:
   flutter pub get

5) Scaffold a feature
   uncle_bob feature organizations

6) Answer the questionnaire — paste JSON straight from your API docs/Postman.
   You will be asked for separate pieces:

   • Query params (optional) — e.g. page/search/filter in URL
   • Request body (POST/PUT/PATCH) — what you SEND
   • Base response — status, message (wrapper fields)
   • Data — one list item or object shape (not the full page)
   • Pagination — paginationData object (if paginated)
   • Reuse last base/pagination defaults, or change them on demand

7) Copy the printed init<Feature>() snippet into injection_container.dart
   and call it from initDependencies().

8) Open the generated screen, wire BlocProvider, and expand entity/model
   fields to match your data example (scaffold starts with id + name).

Tip: run "uncle_bob guide feature" before your first feature for examples.
''');
  }

  static void printFeatureQuestionnaireIntro() {
    stdout.writeln('''
────────────────────────────────────────────────────────────
API questionnaire — paste JSON from your real API response.

Split your response like this:

  BASE (status, message):
${ApiExamples.baseResponse}

  DATA (one item is enough for a list endpoint):
${ApiExamples.dataListItem}

  PAGINATION (if paginated — key is usually paginationData):
${ApiExamples.paginationObject}

Press Enter on the first line of each step to use the example above.
────────────────────────────────────────────────────────────
''');
  }

  static void printAfterInit() {
    stdout.writeln('\nNext: uncle_bob guide');
    stdout.writeln('Then:  uncle_bob feature <name>');
  }

  static void printAfterFeature() {
    stdout.writeln('\nNext steps:');
    stdout.writeln('  1. Paste the DI snippet into injection_container.dart');
    stdout.writeln('  2. Map entity/model fields from your data example');
    stdout.writeln('  3. Wire BlocProvider and navigate to the screen');
    stdout.writeln('\nRun "uncle_bob guide" anytime for the full walkthrough.');
  }
}
