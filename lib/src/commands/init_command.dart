import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../generators/init_generator.dart';
import '../guide/usage_guide.dart';

class InitCommand extends Command<void> {
  @override
  final String name = 'init';

  @override
  final String description = 'Bootstrap core clean architecture layers.';

  InitCommand() {
    argParser.addOption(
      'path',
      help: 'Flutter project root.',
      defaultsTo: Directory.current.path,
    );
  }

  @override
  Future<void> run() async {
    final path = p.normalize(argResults!['path'] as String);
    final root = Directory(path);
    if (!root.existsSync()) {
      throw UsageException('Path does not exist: $path', '');
    }

    stdout.writeln('uncle_bob init → $path');
    await InitGenerator().generate(root);
    await _addCoreDependencies(root);
    stdout.writeln('\nDone.');
    UsageGuide.printAfterInit();
  }

  Future<void> _addCoreDependencies(Directory root) async {
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      stdout.writeln(
        'Skipped dependency install: pubspec.yaml not found in ${root.path}.',
      );
      return;
    }

    final dependencies = ['dartz', 'dio', 'equatable', 'flutter_bloc', 'get_it'];
    final devDependencies = ['bloc'];

    await _runPubAdd(
      root: root,
      packages: dependencies,
      dev: false,
    );
    await _runPubAdd(
      root: root,
      packages: devDependencies,
      dev: true,
    );
  }

  Future<void> _runPubAdd({
    required Directory root,
    required List<String> packages,
    required bool dev,
  }) async {
    final args = ['pub', 'add', if (dev) '--dev', ...packages];
    final result = await Process.run(
      'flutter',
      args,
      workingDirectory: root.path,
      runInShell: true,
    );

    if (result.exitCode == 0) {
      stdout.writeln(
        'Added ${dev ? 'dev ' : ''}dependencies: ${packages.join(', ')}',
      );
      return;
    }

    stderr.writeln(
      'Could not auto-add ${dev ? 'dev ' : ''}dependencies via flutter pub add.',
    );
    stderr.writeln('Run manually in ${root.path}:');
    stderr.writeln('  flutter ${args.join(' ')}');
  }
}
