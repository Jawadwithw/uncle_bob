import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/feature_command.dart';
import 'commands/guide_command.dart';
import 'commands/init_command.dart';

/// Entry point for the `uncle_bob` command-line application.
class UncleBobCli {
  /// Parses [arguments], runs the selected command, and returns an exit code.
  static Future<int> run(List<String> arguments) async {
    final runner = CommandRunner<void>('uncle_bob', _description)
      ..addCommand(GuideCommand())
      ..addCommand(InitCommand())
      ..addCommand(FeatureCommand());

    try {
      await runner.run(arguments);
      return 0;
    } on UsageException catch (error) {
      stderr.writeln(error);
      return 64;
    }
  }

  static const _description = '''
Flutter clean architecture scaffolding CLI.

Run "uncle_bob help <command>" for details.''';
}
