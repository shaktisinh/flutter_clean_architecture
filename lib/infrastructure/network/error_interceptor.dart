import 'package:dio/dio.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ErrorInterceptors extends http.Interceptor {
  final http.Dio dio;
 String? accessToken;
  ErrorInterceptors(this.dio, {required this.accessToken});

  final _storage = const FlutterSecureStorage();

  @override
  void onError(
      http.DioException error, http.ErrorInterceptorHandler handler) async {
    if ((error.response?.statusCode == 401 &&
        error.response?.data['message'] == 'Invalid JWT')) {
      if (await _storage.containsKey(key: 'refreshToken')) {
        if (await refreshToken()) {
          return handler.resolve(await _retry(error.requestOptions));
        }
      }
    } else {
      switch (error.type) {
        case http.DioExceptionType.connectionTimeout:
        case http.DioExceptionType.sendTimeout:
        case http.DioExceptionType.receiveTimeout:
          throw TimeOutException(error.requestOptions);
        case http.DioExceptionType.unknown:
          throw SomethingWringException(error.requestOptions);
        case http.DioExceptionType.connectionError:
          throw NoInternetConnectionException(error.requestOptions);
        case http.DioExceptionType.badCertificate:
          break;
        case http.DioExceptionType.badResponse:
          break;
        case http.DioExceptionType.cancel:
          break;
      }
    }
    return handler.next(error);
  }

  Future<http.Response> _retry(http.RequestOptions requestOptions) async {
    final options = http.Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      options: options,
    );
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    final response =
        await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});

    if (response.statusCode == 201) {
      accessToken = response.data;
      _storage.write(key:'accessToken' , value: accessToken);
      return true;
    } else {
      // refresh token is wrong
      accessToken = null;
      _storage.deleteAll();
      return false;
    }
  }
}

class BadRequestException extends http.DioException {
  BadRequestException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'Invalid request';
  }
}

class InternalServerErrorException extends http.DioException {
  InternalServerErrorException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'Unknown error occurred, please try again later.';
  }
}

class ConflictException extends http.DioException {
  ConflictException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'Conflict occurred';
  }
}

class UnauthorizedException extends http.DioException {
  UnauthorizedException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'Access denied';
  }
}

class NotFoundException extends http.DioException {
  NotFoundException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'The requested information could not be found';
  }
}

class NoInternetConnectionException extends http.DioException {
  NoInternetConnectionException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'No internet connection detected, please try again.';
  }
}

class TimeOutException extends http.DioException {
  TimeOutException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'The connection has timed out, please try again.';
  }
}

class UnknownErrorException extends http.DioException {
  UnknownErrorException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'An unknown error occurred';
  }
}

class SomethingWringException extends http.DioException {
  SomethingWringException(http.RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return 'Oops something went wrong, please try again.';
  }
}