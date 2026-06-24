import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../naming.dart';
import '../project_context.dart';

class FeatureGenerator {
  Future<void> generate(
    Directory root,
    String rawName, {
    required FeatureApiSpec apiSpec,
  }) async {
    final context = ProjectContext.load(root);
    final featureSnake = toSnakeCase(rawName);
    final featurePascal = toPascalCase(rawName);
    final featureCamel = toCamelCase(rawName);
    final package = context.packageName;
    final featureRoot = context.config.featureRoot(featureSnake);

    final replacements = <String, String>{
      '{{package}}': package,
      '{{feature_snake}}': featureSnake,
      '{{feature_pascal}}': featurePascal,
      '{{feature_camel}}': featureCamel,
      '{{endpoint}}': apiSpec.endpoint,
      '{{method}}': apiSpec.method,
      '{{body_example}}': apiSpec.bodyExample.isEmpty
          ? '{}'
          : _escapeMultilineForComment(apiSpec.bodyExample),
      '{{query_params_example}}': apiSpec.queryParamsExample.isEmpty
          ? '{}'
          : _escapeMultilineForComment(apiSpec.queryParamsExample),
      '{{query_params_map}}': _toDartMapLiteral(apiSpec.queryParamsExample),
      '{{base_response_example}}': apiSpec.baseResponseExample.isEmpty
          ? '{}'
          : _escapeMultilineForComment(apiSpec.baseResponseExample),
      '{{data_example}}': apiSpec.dataExample.isEmpty
          ? '[]'
          : _escapeMultilineForComment(apiSpec.dataExample),
      '{{response_example}}': apiSpec.responseExample.isEmpty
          ? '{}'
          : _escapeMultilineForComment(apiSpec.responseExample),
      '{{pagination_example}}': apiSpec.paginationExample.isEmpty
          ? '{}'
          : _escapeMultilineForComment(apiSpec.paginationExample),
      '{{pagination_key}}': apiSpec.paginationKey,
    };

    String tpl(String template) {
      var result = template;
      for (final entry in replacements.entries) {
        result = result.replaceAll(entry.key, entry.value);
      }
      return result;
    }

    final files = _buildFileMap(
      featureRoot: featureRoot,
      featureSnake: featureSnake,
      apiSpec: apiSpec,
      tpl: tpl,
    );

    for (final entry in files.entries) {
      if (entry.key.endsWith('.gitkeep')) {
        await context.writeAlways(entry.key, '');
        continue;
      }
      await context.writeAlways(entry.key, entry.value);
    }

    stdout.writeln('\n--- Add to ${context.config.diFile} ---\n');
    stdout.writeln(tpl(apiSpec.isPaginated ? _diSnippetPaginated : _diSnippet));
    stdout.writeln('--- end snippet ---');
  }

  Map<String, String> _buildFileMap({
    required String featureRoot,
    required String featureSnake,
    required FeatureApiSpec apiSpec,
    required String Function(String template) tpl,
  }) {
    final common = <String, String>{
      p.join(featureRoot, 'domain/entities/${featureSnake}_entity.dart'):
          tpl(_entity),
      p.join(featureRoot, 'data/models/${featureSnake}_model.dart'): tpl(_model),
      p.join(featureRoot, '${featureSnake}_api_contract.json'):
          const JsonEncoder.withIndent('  ').convert({
            'feature': featureSnake,
            'endpoint': apiSpec.endpoint,
            'method': apiSpec.method,
            'is_paginated': apiSpec.isPaginated,
            'body_example': apiSpec.bodyExample,
            'query_params_example': apiSpec.queryParamsExample,
            'base_response_example': apiSpec.baseResponseExample,
            'data_example': apiSpec.dataExample,
            'pagination_example': apiSpec.paginationExample,
            'pagination_key': apiSpec.paginationKey,
            'response_example': apiSpec.responseExample,
          }),
      p.join(featureRoot, 'presentation/widgets/.gitkeep'): '',
    };

    if (apiSpec.isPaginated) {
      return {
        ...common,
        p.join(
          featureRoot,
          'domain/params/get_${featureSnake}_params.dart',
        ): tpl(_paramsPaginated),
        p.join(
          featureRoot,
          'domain/repositories/${featureSnake}_repository.dart',
        ): tpl(_repositoryPaginated),
        p.join(
          featureRoot,
          'domain/usecases/get_${featureSnake}_usecase.dart',
        ): tpl(_usecasePaginated),
        p.join(
          featureRoot,
          'data/datasources/${featureSnake}_remote_datasource.dart',
        ): tpl(_remoteDatasourcePaginated),
        p.join(
          featureRoot,
          'data/repositories/${featureSnake}_repository_impl.dart',
        ): tpl(_repositoryImplPaginated),
        p.join(
          featureRoot,
          'presentation/blocs/get_${featureSnake}_bloc/get_${featureSnake}_bloc.dart',
        ): tpl(_blocPaginated),
        p.join(
          featureRoot,
          'presentation/blocs/get_${featureSnake}_bloc/get_${featureSnake}_event.dart',
        ): tpl(_blocEventPaginated),
        p.join(
          featureRoot,
          'presentation/blocs/get_${featureSnake}_bloc/get_${featureSnake}_state.dart',
        ): tpl(_blocState),
        p.join(
          featureRoot,
          'presentation/screens/${featureSnake}_screen.dart',
        ): tpl(_screenPaginated),
      };
    }

    return {
      ...common,
      p.join(
        featureRoot,
        'domain/repositories/${featureSnake}_repository.dart',
      ): tpl(_repository),
      p.join(
        featureRoot,
        'domain/usecases/get_${featureSnake}_usecase.dart',
      ): tpl(_usecase),
      p.join(
        featureRoot,
        'data/datasources/${featureSnake}_remote_datasource.dart',
      ): tpl(_remoteDatasource),
      p.join(
        featureRoot,
        'data/repositories/${featureSnake}_repository_impl.dart',
      ): tpl(_repositoryImpl),
      p.join(
        featureRoot,
        'presentation/blocs/get_${featureSnake}_bloc/get_${featureSnake}_bloc.dart',
      ): tpl(_bloc),
      p.join(
        featureRoot,
        'presentation/blocs/get_${featureSnake}_bloc/get_${featureSnake}_event.dart',
      ): tpl(_blocEvent),
      p.join(
        featureRoot,
        'presentation/blocs/get_${featureSnake}_bloc/get_${featureSnake}_state.dart',
      ): tpl(_blocState),
      p.join(
        featureRoot,
        'presentation/screens/${featureSnake}_screen.dart',
      ): tpl(_screen),
    };
  }
}

class FeatureApiSpec {
  final String endpoint;
  final String method;
  final String bodyExample;
  final String queryParamsExample;
  final String baseResponseExample;
  final String dataExample;
  final String paginationExample;
  final String paginationKey;
  final String responseExample;
  final bool isPaginated;

  const FeatureApiSpec({
    required this.endpoint,
    required this.method,
    required this.bodyExample,
    required this.queryParamsExample,
    required this.baseResponseExample,
    required this.dataExample,
    required this.paginationExample,
    required this.paginationKey,
    required this.responseExample,
    this.isPaginated = false,
  });
}

String _escapeMultilineForComment(String input) {
  return input.replaceAll('*/', '* /');
}

String _toDartMapLiteral(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '<String, dynamic>{}';
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      final normalized = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return '<String, dynamic>${const JsonEncoder.withIndent('  ').convert(normalized)}';
    }
  } catch (_) {
    // Ignore parse errors and fallback to empty map.
  }
  return '<String, dynamic>{}';
}

const _entity = '''
import 'package:equatable/equatable.dart';

class {{feature_pascal}}Entity extends Equatable {
  final int id;
  final String name;

  const {{feature_pascal}}Entity({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
''';

const _model = '''
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';

class {{feature_pascal}}Model {
  final int id;
  final String name;

  const {{feature_pascal}}Model({
    required this.id,
    required this.name,
  });

  factory {{feature_pascal}}Model.fromJson(Map<String, dynamic> json) {
    return {{feature_pascal}}Model(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  {{feature_pascal}}Entity toEntity() {
    return {{feature_pascal}}Entity(id: id, name: name);
  }
}
''';

const _paramsPaginated = '''
import 'package:equatable/equatable.dart';

class Get{{feature_pascal}}Params extends Equatable {
  final int page;
  final int? perPage;

  const Get{{feature_pascal}}Params({
    required this.page,
    this.perPage,
  });

  @override
  List<Object?> get props => [page, perPage];
}
''';

const _repository = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';

abstract class {{feature_pascal}}Repository {
  Future<Either<Failure, BaseResponseEntity<List<{{feature_pascal}}Entity>>>>
  get{{feature_pascal}}();
}
''';

const _repositoryPaginated = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/domain/entities/base_response_with_pagination_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/params/get_{{feature_snake}}_params.dart';

abstract class {{feature_pascal}}Repository {
  Future<
    Either<
      Failure,
      BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
    >
  >
  get{{feature_pascal}}(Get{{feature_pascal}}Params params);
}
''';

const _remoteDatasource = '''
import 'package:dio/dio.dart';
import 'package:{{package}}/core/data/error/error_handler.dart';
import 'package:{{package}}/core/data/error/exceptions.dart';
import 'package:{{package}}/core/data/models/base_response_model.dart';
import 'package:{{package}}/features/{{feature_snake}}/data/models/{{feature_snake}}_model.dart';

abstract class {{feature_pascal}}RemoteDatasource {
  Future<BaseResponseModel<List<{{feature_pascal}}Model>>> get{{feature_pascal}}();
}

class {{feature_pascal}}RemoteDatasourceImpl implements {{feature_pascal}}RemoteDatasource {
  final Dio dio;
  static const _endpoint = '{{endpoint}}';
  static const _method = '{{method}}';

  {{feature_pascal}}RemoteDatasourceImpl({required this.dio});

  @override
  Future<BaseResponseModel<List<{{feature_pascal}}Model>>> get{{feature_pascal}}() async {
    try {
      /*
      Generated API metadata:
      endpoint: {{endpoint}}
      method: {{method}}
      request body example:
      {{body_example}}
      query params example:
      {{query_params_example}}
      base response example (status, message, extras):
      {{base_response_example}}
      data example:
      {{data_example}}
      full response example:
      {{response_example}}
      */
      final response = await dio.request(
        _endpoint,
        queryParameters: {{query_params_map}},
        data: _method == 'GET' ? null : <String, dynamic>{},
        options: Options(method: _method),
      );
      return BaseResponseModel<List<{{feature_pascal}}Model>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) =>
            (data as List? ?? [])
                .map(
                  (item) => {{feature_pascal}}Model.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );
    } on DioException catch (error) {
      throw ServerException(error: ErrorHandler.handle(error));
    }
  }
}
''';

const _remoteDatasourcePaginated = '''
import 'package:dio/dio.dart';
import 'package:{{package}}/core/data/error/error_handler.dart';
import 'package:{{package}}/core/data/error/exceptions.dart';
import 'package:{{package}}/core/data/models/base_response_with_pagination_model.dart';
import 'package:{{package}}/features/{{feature_snake}}/data/models/{{feature_snake}}_model.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/params/get_{{feature_snake}}_params.dart';

abstract class {{feature_pascal}}RemoteDatasource {
  Future<BaseResponseWithPaginationModel<List<{{feature_pascal}}Model>>>
  get{{feature_pascal}}(Get{{feature_pascal}}Params params);
}

class {{feature_pascal}}RemoteDatasourceImpl implements {{feature_pascal}}RemoteDatasource {
  final Dio dio;
  static const _endpoint = '{{endpoint}}';
  static const _method = '{{method}}';

  {{feature_pascal}}RemoteDatasourceImpl({required this.dio});

  @override
  Future<BaseResponseWithPaginationModel<List<{{feature_pascal}}Model>>>
  get{{feature_pascal}}(Get{{feature_pascal}}Params params) async {
    try {
      /*
      Generated API metadata:
      endpoint: {{endpoint}}
      method: {{method}}
      paginated: true
      request body example:
      {{body_example}}
      query params example:
      {{query_params_example}}
      base response example (status, message, extras):
      {{base_response_example}}
      data example:
      {{data_example}}
      pagination example ({{pagination_key}}):
      {{pagination_example}}
      full response example:
      {{response_example}}
      */
      final response = await dio.request(
        _endpoint,
        queryParameters: {
          'page': params.page,
          if (params.perPage != null) 'per_page': params.perPage,
          ...{{query_params_map}},
        },
        data: _method == 'GET' ? null : <String, dynamic>{},
        options: Options(method: _method),
      );
      return BaseResponseWithPaginationModel<List<{{feature_pascal}}Model>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) =>
            (data as List? ?? [])
                .map(
                  (item) => {{feature_pascal}}Model.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );
    } on DioException catch (error) {
      throw ServerException(error: ErrorHandler.handle(error));
    }
  }
}
''';

const _repositoryImpl = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';
import 'package:{{package}}/core/functions/repository_helper.dart';
import 'package:{{package}}/features/{{feature_snake}}/data/datasources/{{feature_snake}}_remote_datasource.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/repositories/{{feature_snake}}_repository.dart';

class {{feature_pascal}}RepositoryImpl implements {{feature_pascal}}Repository {
  final {{feature_pascal}}RemoteDatasource remoteDatasource;
  final RepositoryHelper helper;

  {{feature_pascal}}RepositoryImpl({
    required this.remoteDatasource,
    required this.helper,
  });

  @override
  Future<Either<Failure, BaseResponseEntity<List<{{feature_pascal}}Entity>>>>
  get{{feature_pascal}}() async {
    return helper.executeWithNetworkCheck(() async {
      final response = await remoteDatasource.get{{feature_pascal}}();
      return BaseResponseEntity<List<{{feature_pascal}}Entity>>(
        status: response.status,
        message: response.message,
        data: response.data?.map((item) => item.toEntity()).toList(),
      );
    });
  }
}
''';

const _repositoryImplPaginated = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/domain/entities/base_response_with_pagination_entity.dart';
import 'package:{{package}}/core/domain/entities/pagination_entity.dart';
import 'package:{{package}}/core/functions/repository_helper.dart';
import 'package:{{package}}/features/{{feature_snake}}/data/datasources/{{feature_snake}}_remote_datasource.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/params/get_{{feature_snake}}_params.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/repositories/{{feature_snake}}_repository.dart';

class {{feature_pascal}}RepositoryImpl implements {{feature_pascal}}Repository {
  final {{feature_pascal}}RemoteDatasource remoteDatasource;
  final RepositoryHelper helper;

  {{feature_pascal}}RepositoryImpl({
    required this.remoteDatasource,
    required this.helper,
  });

  @override
  Future<
    Either<
      Failure,
      BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
    >
  >
  get{{feature_pascal}}(Get{{feature_pascal}}Params params) async {
    return helper.executeWithNetworkCheck(() async {
      final response = await remoteDatasource.get{{feature_pascal}}(params);
      return BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>(
        status: response.status,
        message: response.message,
        data: response.data?.map((item) => item.toEntity()).toList(),
        pagination: PaginationEntity(
          lastPage: response.pagination.lastPage,
          totalCount: response.pagination.totalCount,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
        ),
      );
    });
  }
}
''';

const _usecase = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/data/usecase/usecase.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/repositories/{{feature_snake}}_repository.dart';

class Get{{feature_pascal}}Usecase
    extends Usecase<BaseResponseEntity<List<{{feature_pascal}}Entity>>, NoParams> {
  final {{feature_pascal}}Repository repository;

  Get{{feature_pascal}}Usecase({required this.repository});

  @override
  Future<Either<Failure, BaseResponseEntity<List<{{feature_pascal}}Entity>>>>
  call(NoParams params) {
    return repository.get{{feature_pascal}}();
  }
}
''';

const _usecasePaginated = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/data/usecase/usecase.dart';
import 'package:{{package}}/core/domain/entities/base_response_with_pagination_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/params/get_{{feature_snake}}_params.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/repositories/{{feature_snake}}_repository.dart';

class Get{{feature_pascal}}Usecase
    extends
        Usecase<
          BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>,
          Get{{feature_pascal}}Params
        > {
  final {{feature_pascal}}Repository repository;

  Get{{feature_pascal}}Usecase({required this.repository});

  @override
  Future<
    Either<
      Failure,
      BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
    >
  >
  call(Get{{feature_pascal}}Params params) {
    return repository.get{{feature_pascal}}(params);
  }
}
''';

const _bloc = '''
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:{{package}}/core/data/usecase/usecase.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';
import 'package:{{package}}/core/presentation/blocs/base_state.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/usecases/get_{{feature_snake}}_usecase.dart';

part 'get_{{feature_snake}}_event.dart';
part 'get_{{feature_snake}}_state.dart';

class Get{{feature_pascal}}Bloc
    extends Bloc<Get{{feature_pascal}}Event, BaseState<BaseResponseEntity<List<{{feature_pascal}}Entity>>>> {
  final Get{{feature_pascal}}Usecase usecase;

  Get{{feature_pascal}}Bloc({required this.usecase}) : super(InitialState()) {
    on<Get{{feature_pascal}}>(_onGet{{feature_pascal}});
  }

  FutureOr<void> _onGet{{feature_pascal}}(
    Get{{feature_pascal}} event,
    Emitter<BaseState<BaseResponseEntity<List<{{feature_pascal}}Entity>>>> emit,
  ) async {
    emit(LoadingState());
    final result = await usecase(const NoParams());

    result.fold(
      (failure) => emit(FailureState(error: failure)),
      (response) => emit(SuccessState(data: response)),
    );
  }
}
''';

const _blocPaginated = '''
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:{{package}}/core/domain/entities/base_response_with_pagination_entity.dart';
import 'package:{{package}}/core/presentation/blocs/base_state.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/params/get_{{feature_snake}}_params.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/usecases/get_{{feature_snake}}_usecase.dart';

part 'get_{{feature_snake}}_event.dart';
part 'get_{{feature_snake}}_state.dart';

class Get{{feature_pascal}}Bloc
    extends
        Bloc<
          Get{{feature_pascal}}Event,
          BaseState<BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>>
        > {
  final Get{{feature_pascal}}Usecase usecase;

  Get{{feature_pascal}}Bloc({required this.usecase}) : super(InitialState()) {
    on<Get{{feature_pascal}}>(_onGet{{feature_pascal}});
  }

  List<{{feature_pascal}}Entity> _items = [];

  FutureOr<void> _onGet{{feature_pascal}}(
    Get{{feature_pascal}} event,
    Emitter<BaseState<BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>>>
    emit,
  ) async {
    final isFirstPage = event.params.page == 1;

    if (isFirstPage) {
      _items = [];
      emit(LoadingState());
    }

    final result = await usecase(event.params);

    result.fold((failure) => emit(FailureState(error: failure)), (response) {
      final newItems = response.data ?? [];

      if (isFirstPage) {
        _items = List<{{feature_pascal}}Entity>.from(newItems);
      } else {
        _items = [..._items, ...newItems];
      }

      final merged = BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>(
        status: response.status,
        message: response.message,
        data: List<{{feature_pascal}}Entity>.from(_items),
        pagination: response.pagination,
      );

      emit(SuccessState(data: merged));
    });
  }
}
''';

const _blocEvent = '''
part of 'get_{{feature_snake}}_bloc.dart';

sealed class Get{{feature_pascal}}Event {}

final class Get{{feature_pascal}} extends Get{{feature_pascal}}Event {}
''';

const _blocEventPaginated = '''
part of 'get_{{feature_snake}}_bloc.dart';

sealed class Get{{feature_pascal}}Event {}

final class Get{{feature_pascal}} extends Get{{feature_pascal}}Event {
  final Get{{feature_pascal}}Params params;

  const Get{{feature_pascal}}({required this.params});
}
''';

const _blocState = '''
part of 'get_{{feature_snake}}_bloc.dart';

// States use shared BaseState in get_{{feature_snake}}_bloc.dart.
''';

const _screen = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';
import 'package:{{package}}/core/presentation/blocs/base_state.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/presentation/blocs/get_{{feature_snake}}_bloc/get_{{feature_snake}}_bloc.dart';

class {{feature_pascal}}Screen extends StatelessWidget {
  const {{feature_pascal}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_pascal}}')),
      body: BlocBuilder<
        Get{{feature_pascal}}Bloc,
        BaseState<BaseResponseEntity<List<{{feature_pascal}}Entity>>>
      >(
        builder: (context, state) {
          if (state
              is LoadingState<BaseResponseEntity<List<{{feature_pascal}}Entity>>>) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state
              is FailureState<BaseResponseEntity<List<{{feature_pascal}}Entity>>>) {
            return Center(child: Text(state.error.message));
          }

          if (state is SuccessState<BaseResponseEntity<List<{{feature_pascal}}Entity>>>) {
            final items = state.data.data ?? [];
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('#\${item.id}'),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<Get{{feature_pascal}}Bloc>().add(Get{{feature_pascal}}()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
''';

const _screenPaginated = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{package}}/core/domain/entities/base_response_with_pagination_entity.dart';
import 'package:{{package}}/core/presentation/blocs/base_state.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/entities/{{feature_snake}}_entity.dart';
import 'package:{{package}}/features/{{feature_snake}}/domain/params/get_{{feature_snake}}_params.dart';
import 'package:{{package}}/features/{{feature_snake}}/presentation/blocs/get_{{feature_snake}}_bloc/get_{{feature_snake}}_bloc.dart';

class {{feature_pascal}}Screen extends StatefulWidget {
  const {{feature_pascal}}Screen({super.key});

  @override
  State<{{feature_pascal}}Screen> createState() => _{{feature_pascal}}ScreenState();
}

class _{{feature_pascal}}ScreenState extends State<{{feature_pascal}}Screen> {
  late final ScrollController _scrollController;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPage(1));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchPage(int page) {
    _isFetching = true;
    context.read<Get{{feature_pascal}}Bloc>().add(
      Get{{feature_pascal}}(params: Get{{feature_pascal}}Params(page: page)),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isFetching) return;

    final state = context.read<Get{{feature_pascal}}Bloc>().state;
    if (state
        is! SuccessState<BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>>) {
      return;
    }

    final pagination = state.data.pagination;
    final isNearBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80;

    if (isNearBottom && pagination.hasNextPage) {
      _fetchPage(pagination.currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_pascal}}')),
      body: BlocConsumer<
        Get{{feature_pascal}}Bloc,
        BaseState<BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>>
      >(
        listener: (context, state) {
          if (state
                  is SuccessState<
                    BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
                  > ||
              state is FailureState) {
            _isFetching = false;
          }
        },
        builder: (context, state) {
          if (state
              is LoadingState<
                BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
              >) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state
              is FailureState<
                BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
              >) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error.message),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _fetchPage(1),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state
              is SuccessState<
                BaseResponseWithPaginationEntity<List<{{feature_pascal}}Entity>>
              >) {
            final items = state.data.data ?? [];
            final pagination = state.data.pagination;

            if (items.isEmpty) {
              return const Center(child: Text('No items found'));
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: items.length + (pagination.hasNextPage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('#\${item.id}'),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _fetchPage(1),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
''';

const _diSnippet = '''
void init{{feature_pascal}}() {
  sl.registerFactory(() => Get{{feature_pascal}}Bloc(usecase: sl()));
  sl.registerLazySingleton(() => Get{{feature_pascal}}Usecase(repository: sl()));
  sl.registerLazySingleton<{{feature_pascal}}Repository>(
    () => {{feature_pascal}}RepositoryImpl(remoteDatasource: sl(), helper: sl()),
  );
  sl.registerLazySingleton<{{feature_pascal}}RemoteDatasource>(
    () => {{feature_pascal}}RemoteDatasourceImpl(dio: sl()),
  );
}
''';

const _diSnippetPaginated = _diSnippet;
