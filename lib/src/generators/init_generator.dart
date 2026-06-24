import 'dart:io';

import 'package:path/path.dart' as p;

import '../project_context.dart';
import 'template_helper.dart';

class InitGenerator {
  Future<void> generate(Directory root) async {
    final context = ProjectContext.load(root);

    await context.writeAlways('uncle_bob.yaml', context.config.toYaml());

    final files = <String, String>{
      p.join(context.config.corePath, 'domain/entities/base_response_entity.dart'):
          _baseResponseEntity,
      p.join(context.config.corePath, 'domain/entities/pagination_entity.dart'):
          _paginationEntity,
      p.join(context.config.corePath, 'data/error/failures.dart'): _failures,
      p.join(context.config.corePath, 'data/error/exceptions.dart'): _exceptions,
      p.join(context.config.corePath, 'data/error/error_handler.dart'):
          _errorHandler,
      p.join(context.config.corePath, 'data/models/error_response_model.dart'):
          _errorResponseModel,
      p.join(context.config.corePath, 'data/models/base_response_model.dart'):
          _baseResponseModel,
      p.join(
        context.config.corePath,
        'data/models/base_response_with_pagination_model.dart',
      ): _baseResponseWithPaginationModel,
      p.join(
        context.config.corePath,
        'domain/entities/base_response_with_pagination_entity.dart',
      ): _baseResponseWithPaginationEntity,
      p.join(context.config.corePath, 'data/usecase/usecase.dart'): _usecase,
      p.join(context.config.corePath, 'data/network/network_info.dart'):
          _networkInfo,
      p.join(context.config.corePath, 'functions/repository_helper.dart'):
          _repositoryHelper,
      p.join(context.config.corePath, 'presentation/blocs/base_state.dart'):
          _baseState,
    };

    for (final entry in files.entries) {
      await context.writeIfMissing(
        entry.key,
        applyTemplate(entry.value, context.packageName),
      );
    }

    await context.writeIfMissing(
      context.config.diFile,
      applyTemplate(_injectionContainerStub, context.packageName),
    );
  }
}

const _baseResponseEntity = '''
import 'package:equatable/equatable.dart';

class BaseResponseEntity<T> extends Equatable {
  final bool status;
  final String message;
  final T? data;

  const BaseResponseEntity({
    required this.status,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}
''';

const _paginationEntity = '''
import 'package:equatable/equatable.dart';

class PaginationEntity extends Equatable {
  final int lastPage;
  final int totalCount;
  final int perPage;
  final int currentPage;

  const PaginationEntity({
    required this.lastPage,
    required this.totalCount,
    required this.perPage,
    required this.currentPage,
  });

  bool get hasNextPage => currentPage < lastPage;

  @override
  List<Object?> get props => [lastPage, totalCount, perPage, currentPage];
}
''';

const _baseResponseWithPaginationEntity = '''
import 'package:equatable/equatable.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';
import 'package:{{package}}/core/domain/entities/pagination_entity.dart';

class BaseResponseWithPaginationEntity<T> extends BaseResponseEntity<T> {
  final PaginationEntity pagination;

  const BaseResponseWithPaginationEntity({
    required super.status,
    required super.message,
    super.data,
    required this.pagination,
  });

  @override
  List<Object?> get props => [...super.props, pagination];
}
''';

const _failures = '''
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';

abstract class Failure extends BaseResponseEntity<void> {
  const Failure({
    required super.status,
    required super.message,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.status,
    required super.message,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message}) : super(status: false);
}

class OfflineFailure extends Failure {
  const OfflineFailure()
      : super(status: false, message: 'No Internet Connection');
}
''';

const _exceptions = '''
import 'package:{{package}}/core/data/models/error_response_model.dart';

class ServerException implements Exception {
  final ErrorResponseModel error;

  ServerException({required this.error});
}

class CacheException implements Exception {}
''';

const _errorHandler = '''
import 'package:dio/dio.dart';
import 'package:{{package}}/core/data/models/error_response_model.dart';

class ErrorHandler {
  static ErrorResponseModel handle(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return ErrorResponseModel.fromJson(data);
    }

    return ErrorResponseModel(
      status: false,
      message: error.message ?? 'Server error',
    );
  }
}
''';

const _errorResponseModel = '''
import 'package:equatable/equatable.dart';

class ErrorResponseModel extends Equatable {
  final bool status;
  final String message;

  const ErrorResponseModel({
    required this.status,
    required this.message,
  });

  factory ErrorResponseModel.fromJson(Map<String, dynamic> json) {
    return ErrorResponseModel(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? 'Unknown error',
    );
  }

  @override
  List<Object?> get props => [status, message];
}
''';

const _baseResponseModel = '''
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';

class BaseResponseModel<T> extends BaseResponseEntity<T> {
  const BaseResponseModel({
    required super.status,
    required super.message,
    super.data,
  });

  factory BaseResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return BaseResponseModel<T>(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] == null ? null : fromJsonT(json['data']),
    );
  }
}
''';

const _baseResponseWithPaginationModel = '''
import 'package:{{package}}/core/data/models/base_response_model.dart';
import 'package:{{package}}/core/domain/entities/base_response_with_pagination_entity.dart';
import 'package:{{package}}/core/domain/entities/pagination_entity.dart';

class BaseResponseWithPaginationModel<T>
    extends BaseResponseWithPaginationEntity<T> {
  const BaseResponseWithPaginationModel({
    required super.status,
    required super.message,
    super.data,
    required super.pagination,
  });

  factory BaseResponseWithPaginationModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final paginationJson =
        json['paginationData'] as Map<String, dynamic>? ??
        json['pagination'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    return BaseResponseWithPaginationModel<T>(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] == null ? null : fromJsonT(json['data']),
      pagination: PaginationEntity(
        lastPage: paginationJson['last_page'] ?? 1,
        totalCount: paginationJson['total'] ?? 0,
        perPage: paginationJson['per_page'] ?? 15,
        currentPage: paginationJson['current_page'] ?? 1,
      ),
    );
  }
}
''';

const _usecase = '''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:{{package}}/core/data/error/failures.dart';

abstract class Usecase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
''';

const _networkInfo = '''
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Wire this to connectivity_plus or data_connection_checker in DI.
class NetworkInfoImpl implements NetworkInfo {
  final Future<bool> Function() checker;

  NetworkInfoImpl({required this.checker});

  @override
  Future<bool> get isConnected => checker();
}
''';

const _repositoryHelper = '''
import 'package:dartz/dartz.dart';
import 'package:{{package}}/core/data/error/exceptions.dart';
import 'package:{{package}}/core/data/error/failures.dart';
import 'package:{{package}}/core/data/network/network_info.dart';

class RepositoryHelper {
  final NetworkInfo networkInfo;

  RepositoryHelper(this.networkInfo);

  Future<Either<Failure, T>> executeWithNetworkCheck<T>(
    Future<T> Function() action,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(OfflineFailure());
    }

    try {
      final result = await action();
      return Right(result);
    } on ServerException catch (error) {
      return Left(
        ServerFailure(status: error.error.status, message: error.error.message),
      );
    }
  }
}
''';

const _baseState = '''
import 'package:equatable/equatable.dart';
import 'package:{{package}}/core/domain/entities/base_response_entity.dart';

sealed class BaseState<T> extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

final class InitialState<T> extends BaseState<T> {}

final class LoadingState<T> extends BaseState<T> {}

final class SuccessState<T> extends BaseState<T> {
  final T data;

  const SuccessState({required this.data});

  @override
  List<Object?> get props => [data];
}

final class FailureState<T> extends BaseState<T> {
  final BaseResponseEntity error;

  const FailureState({required this.error});

  @override
  List<Object?> get props => [error];
}
''';

const _injectionContainerStub = '''
import 'package:get_it/get_it.dart';
import 'package:{{package}}/core/data/network/network_info.dart';
import 'package:{{package}}/core/functions/repository_helper.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(checker: () async => true),
  );
  sl.registerLazySingleton(() => RepositoryHelper(sl()));
}
''';
