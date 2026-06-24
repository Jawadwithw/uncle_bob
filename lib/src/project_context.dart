import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'config.dart';

/// Loaded Flutter/Dart project context for code generation.
class ProjectContext {
  final Directory root;
  final String packageName;
  final UncleBobConfig config;

  ProjectContext({
    required this.root,
    required this.packageName,
    required this.config,
  });

  factory ProjectContext.load(Directory root) {
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw StateError(
        'No pubspec.yaml found in ${root.path}. Run this inside a Flutter/Dart project.',
      );
    }

    final pubspec = loadYaml(pubspecFile.readAsStringSync());
    final packageName =
        pubspec is YamlMap ? pubspec['name']?.toString() : null;
    if (packageName == null || packageName.isEmpty) {
      throw StateError('Could not read package name from pubspec.yaml.');
    }

    final configFile = File(p.join(root.path, 'uncle_bob.yaml'));
    final config = UncleBobConfig.fromYamlFile(
      configFile,
      packageName: packageName,
    );

    return ProjectContext(root: root, packageName: packageName, config: config);
  }

  File file(String relativePath) => File(p.join(root.path, relativePath));

  Future<void> writeIfMissing(String relativePath, String content) async {
    final target = file(relativePath);
    if (target.existsSync()) {
      stdout.writeln('skip  ${p.normalize(relativePath)} (already exists)');
      return;
    }

    await target.parent.create(recursive: true);
    await target.writeAsString(content);
    stdout.writeln('create ${p.normalize(relativePath)}');
  }

  Future<void> writeAlways(String relativePath, String content) async {
    final target = file(relativePath);
    await target.parent.create(recursive: true);
    await target.writeAsString(content);
    stdout.writeln('create ${p.normalize(relativePath)}');
  }
}
