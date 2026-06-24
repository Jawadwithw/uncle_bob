import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../constants/api_examples.dart';
import '../constants/pagination_keys.dart';
import '../config.dart';
import '../generators/feature_generator.dart';
import '../guide/usage_guide.dart';
import '../project_context.dart';
import '../utils/pagination_detector.dart';
import '../utils/response_composer.dart';

class FeatureCommand extends Command<void> {
  @override
  final String name = 'feature';

  @override
  final String description =
      'Scaffold a feature module (data / domain / presentation).';

  FeatureCommand() {
    argParser.addOption(
      'path',
      help: 'Flutter project root.',
      defaultsTo: Directory.current.path,
    );
    argParser.addFlag(
      'no-prompt',
      negatable: false,
      help: 'Skip questionnaire and use provided flags/defaults.',
    );
    argParser.addOption(
      'endpoint',
      help: 'API endpoint, e.g. /number-lookup',
    );
    argParser.addOption(
      'method',
      help: 'REST method: GET, POST, PUT, PATCH, DELETE',
    );
    argParser.addOption(
      'body',
      help: 'Example request body JSON string.',
    );
    argParser.addOption(
      'params',
      help: 'Example query params JSON object string.',
    );
    argParser.addOption(
      'response',
      help: 'Full example response JSON (split into base/data/pagination).',
    );
    argParser.addOption(
      'response-base',
      help: 'Example base response JSON (status, message, extras).',
    );
    argParser.addOption(
      'response-data',
      help: 'Example response data JSON (item or list shape).',
    );
    argParser.addOption(
      'body-file',
      help: 'Path to a file containing example request body JSON.',
    );
    argParser.addOption(
      'params-file',
      help: 'Path to a file containing example query params JSON object.',
    );
    argParser.addOption(
      'response-file',
      help: 'Path to a file containing full example response JSON.',
    );
    argParser.addOption(
      'response-base-file',
      help: 'Path to file containing base response JSON.',
    );
    argParser.addOption(
      'response-data-file',
      help: 'Path to file containing response data JSON.',
    );
    argParser.addFlag(
      'paginated',
      help: 'Force paginated API generation.',
    );
    argParser.addFlag(
      'no-paginated',
      help: 'Force non-paginated API generation.',
    );
    argParser.addOption(
      'pagination',
      help: 'Example pagination JSON object string.',
    );
    argParser.addOption(
      'pagination-file',
      help: 'Path to file containing example pagination JSON object.',
    );
  }

  @override
  Future<void> run() async {
    final path = p.normalize(argResults!['path'] as String);
    final root = Directory(path);
    if (!root.existsSync()) {
      throw UsageException('Path does not exist: $path', '');
    }

    final positional = argResults!.rest;
    if (positional.isEmpty) {
      throw UsageException(
        'Missing feature name.',
        'Example: uncle_bob feature settings',
      );
    }

    final featureName = positional.first;
    stdout.writeln('uncle_bob feature $featureName → $path');
    final context = ProjectContext.load(root);
    final noPrompt = argResults!['no-prompt'] as bool;
    final apiSpec =
        noPrompt
            ? _specFromFlags(featureName)
            : _askApiQuestionnaire(featureName, context.config);
    await FeatureGenerator().generate(root, featureName, apiSpec: apiSpec);
    _saveApiDefaults(root, context.config, apiSpec);
    UsageGuide.printAfterFeature();
  }

  FeatureApiSpec _askApiQuestionnaire(
    String featureName,
    UncleBobConfig config,
  ) {
    UsageGuide.printFeatureQuestionnaireIntro();

    stdout.writeln('Feature questionnaire for "$featureName"\n');

    final endpoint = _prompt(
      '1) Endpoint path',
      defaultValue:
          (argResults!['endpoint'] as String?)?.trim().isNotEmpty == true
              ? (argResults!['endpoint'] as String).trim()
              : '/$featureName',
    ).trim();

    final method = _promptMethod(defaultValue: _methodFromArgs());

    final queryParamsExample = _promptJsonWithExample(
      '3) Query params JSON (optional)',
      example: ApiExamples.queryParams,
      initialValue: _paramsFromArgs(),
      optional: true,
    );

    final bodyExample = _promptJsonWithExample(
      '4) Request body JSON (skip for GET)',
      example: ApiExamples.requestBody,
      initialValue: _bodyFromArgs(),
      optional: true,
    );

    final prefilledParts = _responsePartsFromArgs();

    final rememberedBase = config.lastBaseResponseExample.trim();
    final hasRememberedBase = rememberedBase.isNotEmpty;
    late final String baseResponseExample;
    if (prefilledParts.baseResponseExample.isNotEmpty) {
      baseResponseExample = _promptJsonWithExample(
        '5) Base response JSON (status, message)',
        example: ApiExamples.baseResponse,
        initialValue: prefilledParts.baseResponseExample,
      );
    } else if (hasRememberedBase &&
        _promptYesNo('5) Use saved base response from previous feature?', defaultYes: true)) {
      baseResponseExample = rememberedBase;
    } else {
      baseResponseExample = _promptJsonWithExample(
        '5) Base response JSON (status, message)',
        example: ApiExamples.baseResponse,
      );
    }

    final dataExample = _promptJsonWithExample(
      '6) Response data JSON (paste one list item, not the full page)',
      example: ApiExamples.dataListItem,
      initialValue:
          prefilledParts.dataExample.isNotEmpty
              ? prefilledParts.dataExample
              : null,
    );

    var paginationPrefill = _paginationFromArgs().isNotEmpty
        ? _paginationFromArgs()
        : prefilledParts.paginationExample;
    if (paginationPrefill.isEmpty) {
      paginationPrefill = config.lastPaginationExample.trim();
    }

    final rememberedPaginationKey = config.lastPaginationKey.trim().isNotEmpty
        ? config.lastPaginationKey.trim()
        : PaginationKeys.defaultKey;
    final paginationKey = prefilledParts.paginationExample.isNotEmpty
        ? prefilledParts.paginationKey
        : config.lastPaginationExample.trim().isNotEmpty
            ? rememberedPaginationKey
            : PaginationDetector.detectKeyFromResponse(_responseFromArgs());

    final composedPreview = ResponseComposer.compose(
      baseResponseExample: baseResponseExample,
      dataExample: dataExample,
      paginationExample: paginationPrefill,
      includePagination: paginationPrefill.isNotEmpty,
      paginationKey: paginationKey,
    );

    final autoDetected =
        paginationPrefill.isNotEmpty ||
        PaginationDetector.detectFromResponse(composedPreview);

    if (autoDetected) {
      stdout.writeln('\nDetected pagination in your examples.');
    }

    final isPaginated = _promptYesNo(
      '7) Is this API paginated?',
      defaultYes: autoDetected || (argResults!['paginated'] as bool),
    );

    var paginationExample = '';
    var resolvedPaginationKey = paginationKey;
    if (isPaginated) {
      if (paginationPrefill.isNotEmpty &&
          _promptYesNo(
            '8) Use saved pagination object from previous feature?',
            defaultYes: true,
          )) {
        paginationExample = paginationPrefill;
      } else {
        paginationExample = _promptJsonWithExample(
          '8) Pagination JSON (usually under paginationData in the API)',
          example: ApiExamples.paginationObject,
          initialValue:
              paginationPrefill.isNotEmpty ? paginationPrefill : null,
        );
      }
      resolvedPaginationKey =
          prefilledParts.paginationExample.isNotEmpty
              ? prefilledParts.paginationKey
              : PaginationDetector.detectKeyFromResponse(
                ResponseComposer.compose(
                  baseResponseExample: baseResponseExample,
                  dataExample: dataExample,
                  paginationExample: paginationExample,
                  includePagination: true,
                  paginationKey: paginationKey,
                ),
              );
    }

    return _buildSpec(
      endpoint: endpoint,
      method: method,
      bodyExample: bodyExample,
      queryParamsExample: queryParamsExample,
      baseResponseExample: baseResponseExample,
      dataExample: dataExample,
      isPaginated: isPaginated,
      paginationExample: paginationExample,
      paginationKey: resolvedPaginationKey,
    );
  }

  FeatureApiSpec _specFromFlags(String featureName) {
    final paginatedFlag = argResults!['paginated'] as bool;
    final noPaginatedFlag = argResults!['no-paginated'] as bool;
    if (paginatedFlag && noPaginatedFlag) {
      throw UsageException(
        'Use only one of --paginated or --no-paginated.',
        usage,
      );
    }

    final parts = _responsePartsFromArgs();
    var paginationExample = _paginationFromArgs().isNotEmpty
        ? _paginationFromArgs()
        : parts.paginationExample;
    var paginationKey = parts.paginationKey;

    final composedPreview = ResponseComposer.compose(
      baseResponseExample: parts.baseResponseExample,
      dataExample: parts.dataExample,
      paginationExample: paginationExample,
      includePagination: paginationExample.isNotEmpty,
      paginationKey: paginationKey,
    );

    final autoDetected =
        paginationExample.isNotEmpty ||
        PaginationDetector.detectFromResponse(composedPreview);

    final isPaginated =
        paginatedFlag
            ? true
            : noPaginatedFlag
            ? false
            : autoDetected;

    if (paginationExample.isEmpty && isPaginated) {
      final extracted = PaginationDetector.extractFromResponse(composedPreview);
      paginationExample =
          extracted.isNotEmpty
              ? extracted
              : ResponseComposer.defaultPaginationExample;
      paginationKey = PaginationDetector.detectKeyFromResponse(
        _responseFromArgs().isNotEmpty
            ? _responseFromArgs()
            : composedPreview,
      );
    }

    return _buildSpec(
      endpoint:
          (argResults!['endpoint'] as String?)?.trim().isNotEmpty == true
              ? (argResults!['endpoint'] as String).trim()
              : '/$featureName',
      method: _methodFromArgs(),
      bodyExample: _bodyFromArgs(),
      queryParamsExample: _paramsFromArgs(),
      baseResponseExample: parts.baseResponseExample,
      dataExample: parts.dataExample,
      isPaginated: isPaginated,
      paginationExample: paginationExample,
      paginationKey: paginationKey,
    );
  }

  FeatureApiSpec _buildSpec({
    required String endpoint,
    required String method,
    required String bodyExample,
    required String queryParamsExample,
    required String baseResponseExample,
    required String dataExample,
    required bool isPaginated,
    required String paginationExample,
    required String paginationKey,
  }) {
    final responseExample = ResponseComposer.compose(
      baseResponseExample: baseResponseExample,
      dataExample: dataExample,
      paginationExample: paginationExample,
      includePagination: isPaginated,
      paginationKey: paginationKey,
    );

    return FeatureApiSpec(
      endpoint: endpoint,
      method: method,
      bodyExample: bodyExample,
      queryParamsExample: queryParamsExample,
      baseResponseExample: baseResponseExample,
      dataExample: dataExample,
      paginationExample: paginationExample,
      paginationKey: paginationKey,
      responseExample: responseExample,
      isPaginated: isPaginated,
    );
  }

  ResponseParts _responsePartsFromArgs() {
    final baseFromFile = _readOptionalFile(
      argResults!['response-base-file'] as String?,
      '--response-base-file',
    );
    final dataFromFile = _readOptionalFile(
      argResults!['response-data-file'] as String?,
      '--response-data-file',
    );
    final baseFromArg = (argResults!['response-base'] as String?)?.trim() ?? '';
    final dataFromArg = (argResults!['response-data'] as String?)?.trim() ?? '';

    final explicitParts = ResponseParts(
      baseResponseExample:
          baseFromFile.isNotEmpty ? baseFromFile : baseFromArg,
      dataExample: dataFromFile.isNotEmpty ? dataFromFile : dataFromArg,
    );

    if (explicitParts.baseResponseExample.isNotEmpty ||
        explicitParts.dataExample.isNotEmpty) {
      final fullResponse = _responseFromArgs();
      if (fullResponse.isEmpty) {
        return explicitParts;
      }

      final split = ResponseComposer.split(fullResponse);
      return ResponseParts(
        baseResponseExample:
            explicitParts.baseResponseExample.isNotEmpty
                ? explicitParts.baseResponseExample
                : split.baseResponseExample,
        dataExample:
            explicitParts.dataExample.isNotEmpty
                ? explicitParts.dataExample
                : split.dataExample,
        paginationExample: split.paginationExample,
        paginationKey: split.paginationKey,
      );
    }

    final fullResponse = _responseFromArgs();
    if (fullResponse.isNotEmpty) {
      return ResponseComposer.split(fullResponse);
    }

    return const ResponseParts();
  }

  String _methodFromArgs() {
    final raw = (argResults!['method'] as String?)?.trim().toUpperCase();
    if (raw == null || raw.isEmpty) return 'GET';
    if (!_methods.contains(raw)) {
      throw UsageException(
        'Invalid --method "$raw". Use one of: ${_methods.join(', ')}',
        usage,
      );
    }
    return raw;
  }

  String _readOptionalFile(String? filePath, String label) {
    if (filePath == null || filePath.trim().isEmpty) return '';
    final file = File(filePath.trim());
    if (!file.existsSync()) {
      throw UsageException('$label file not found: ${file.path}', usage);
    }
    return file.readAsStringSync().trim();
  }

  String _bodyFromArgs() {
    final bodyFile = _readOptionalFile(
      argResults!['body-file'] as String?,
      '--body-file',
    );
    if (bodyFile.isNotEmpty) return bodyFile;
    return (argResults!['body'] as String?)?.trim() ?? '';
  }

  String _paramsFromArgs() {
    final paramsFile = _readOptionalFile(
      argResults!['params-file'] as String?,
      '--params-file',
    );
    if (paramsFile.isNotEmpty) return paramsFile;
    return (argResults!['params'] as String?)?.trim() ?? '';
  }

  String _responseFromArgs() {
    final responseFile = _readOptionalFile(
      argResults!['response-file'] as String?,
      '--response-file',
    );
    if (responseFile.isNotEmpty) return responseFile;
    return (argResults!['response'] as String?)?.trim() ?? '';
  }

  String _paginationFromArgs() {
    final paginationFile = _readOptionalFile(
      argResults!['pagination-file'] as String?,
      '--pagination-file',
    );
    if (paginationFile.isNotEmpty) return paginationFile;
    return (argResults!['pagination'] as String?)?.trim() ?? '';
  }

  String _promptMethod({required String defaultValue}) {
    const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
    stdout.writeln('2) Choose your REST method:');
    for (var i = 0; i < methods.length; i++) {
      stdout.writeln('   ${i + 1}) ${methods[i]}');
    }

    while (true) {
      stdout.write('Method [default: $defaultValue]: ');
      final input = stdin.readLineSync()?.trim().toUpperCase() ?? '';
      if (input.isEmpty) return defaultValue;

      final asIndex = int.tryParse(input);
      if (asIndex != null && asIndex >= 1 && asIndex <= methods.length) {
        return methods[asIndex - 1];
      }

      if (methods.contains(input)) return input;
      stdout.writeln('Invalid method. Enter 1-5 or method name.');
    }
  }

  bool _promptYesNo(String label, {required bool defaultYes}) {
    final defaultLabel = defaultYes ? 'Y/n' : 'y/N';
    while (true) {
      stdout.write('$label ($defaultLabel): ');
      final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      if (input.isEmpty) return defaultYes;
      if (input == 'y' || input == 'yes') return true;
      if (input == 'n' || input == 'no') return false;
      stdout.writeln('Please enter y or n.');
    }
  }

  String _prompt(String label, {String? defaultValue}) {
    if (defaultValue == null || defaultValue.isEmpty) {
      stdout.write('$label: ');
      return stdin.readLineSync() ?? '';
    }
    stdout.write('$label [default: $defaultValue]: ');
    final value = stdin.readLineSync();
    if (value == null || value.trim().isEmpty) return defaultValue;
    return value;
  }

  String _promptJsonWithExample(
    String label, {
    required String example,
    String? initialValue,
    bool optional = false,
  }) {
    stdout.writeln(label);
    stdout.writeln('Example:');
    stdout.writeln(example.trim());

    if (initialValue != null && initialValue.isNotEmpty) {
      stdout.writeln('\nPrefilled from flag/file:');
      stdout.writeln(initialValue.trim());
      stdout.write('Press Enter to keep, type "edit" to replace: ');
      final decision = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      if (decision.isEmpty || decision == 'keep') {
        return initialValue.trim();
      }
    }

    if (optional) {
      stdout.writeln(
        '\nPress Enter to skip, or paste your JSON (empty line to finish):',
      );
    } else {
      stdout.writeln(
        '\nPress Enter to use example, or paste your JSON (empty line to finish):',
      );
    }

    stdout.write('> ');
    final firstLine = stdin.readLineSync();
    if (firstLine == null || firstLine.trim().isEmpty) {
      return optional ? '' : example.trim();
    }

    final lines = [firstLine];
    while (true) {
      final line = stdin.readLineSync();
      if (line == null || line.trim().isEmpty) break;
      lines.add(line);
    }

    final pasted = lines.join('\n').trim();
    if (pasted.isEmpty) {
      return optional ? '' : example.trim();
    }
    return pasted;
  }

  static const _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

  void _saveApiDefaults(
    Directory root,
    UncleBobConfig config,
    FeatureApiSpec apiSpec,
  ) {
    final updated = config.copyWith(
      lastBaseResponseExample: apiSpec.baseResponseExample,
      lastPaginationExample:
          apiSpec.isPaginated ? apiSpec.paginationExample : '',
      lastPaginationKey:
          apiSpec.isPaginated ? apiSpec.paginationKey : '',
    );
    final file = File(p.join(root.path, 'uncle_bob.yaml'));
    file.writeAsStringSync(updated.toYaml());
  }
}
