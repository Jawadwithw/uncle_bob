import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:uncle_bob/src/cli.dart';

Future<void> main(List<String> arguments) async {
  try {
    final exitCode = await UncleBobCli.run(arguments);
    exit(exitCode);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exit(64);
  } catch (error, stackTrace) {
    stderr.writeln('uncle_bob failed: $error');
    stderr.writeln(stackTrace);
    exit(1);
  }
}
