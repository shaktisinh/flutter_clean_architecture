import 'dart:io';

import 'package:boiler_plate/infrastructure/infrastructure_constants.dart';
import 'package:boiler_plate/infrastructure/network/auth_interceptor.dart';
import 'package:boiler_plate/infrastructure/network/error_interceptor.dart';
import 'package:boiler_plate/infrastructure/network/log_interceptor.dart';
import 'package:boiler_plate/infrastructure/network/network_response.dart';
import 'package:dio/dio.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum RequestType { GET, POST, PUT, PATCH, DELETE }

class Api {
  final dio = createDio();

  Api._internal();

  static final _singleton = Api._internal();

  factory Api() => _singleton;

  static String? _accessToken;

  final _storage = const FlutterSecureStorage();

  static http.Dio createDio() {
    var dio = http.Dio(http.BaseOptions(
      baseUrl: baseUrl,
      receiveTimeout: Duration(seconds: receiveTimeout),
      connectTimeout: Duration(seconds: connectTimeout),
      sendTimeout: Duration(seconds: sendTimeout),
    ));

    dio.interceptors.addAll({
      AuthInterceptor(dio),
    });

    dio.interceptors.addAll({ErrorInterceptors(dio,accessToken: _accessToken)});

    if (kDebugMode) {
      dio.interceptors.addAll({
        Logging(dio),
      });
    }
    return dio;
  }

  Future<NetworkResponse?> apiCall(
      String url,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? body,
      RequestType requestType) async {
    late http.Response result;
    try {
      http.Options options = http.Options(headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_storage.read(key: 'accessToken')}',
        'platform': Platform.localeName,
      });

      switch (requestType) {
        case RequestType.GET:
          result = await dio.get(url,
              queryParameters: queryParameters, options: options);
          break;

        case RequestType.POST:
          result = await dio.post(url, data: body, options: options);
          break;
        case RequestType.DELETE:
          result =
              await dio.delete(url, data: queryParameters, options: options);
          break;

        case RequestType.PUT:
          result = await dio.put(url, data: body, options: options);
          break;
        case RequestType.PATCH:
          result = await dio.patch(url, data: body, options: options);
          break;
      }
      return NetworkResponse.success(result.data);
    } on ERROR catch (error) {
      return NetworkResponse.error(error.toString());
    } catch (error) {
      return NetworkResponse.error(error.toString());
    }
  }

  // ApiService() {
  // api.interceptors.add(dio.InterceptorsWrapper(
  //   onRequest: (options, handler) async {
  //     if (!options.path.contains('http')) {
  //       options.path = 'http://192.168.0.20:8080' + options.path;
  //     }
  //     options.headers['Authorization'] = 'Bearer $accessToken';
  //     return handler.next(options);
  //   },
  //   onError: (error, handler) async {
  //     if ((error.response?.statusCode == 401 &&
  //         error.response?.data['message'] == "Invalid JWT")) {
  //       if (await _storage.containsKey(key: 'refreshToken')) {
  //         if (await refreshToken()) {
  //           return handler.resolve(await _retry(error.requestOptions));
  //         }
  //       }
  //     }
  //     return handler.next(error);
  //   },
  //   onResponse: (response, handler) {
  //     return handler.next(response);
  //   },
  // ));
  // }

  // Future<dio.Response> _retry(dio.RequestOptions requestOptions) async {
  //   final options = dio.Options(
  //     method: requestOptions.method,
  //     headers: requestOptions.headers,
  //   );

  //   return api.request(
  //     requestOptions.path,
  //     data: requestOptions.data,
  //     options: options,
  //   );
  // }

  // Future<bool> refreshToken() async {
  //   final refreshToken = await _storage.read(key: 'refreshToken');
  //   final response =
  //       await api.post('/auth/refresh', data: {'refreshToken': refreshToken});

  //   if (response.statusCode == 201) {
  //     accessToken = response.data;
  //     return true;
  //   } else {
  //     // refresh token is wrong
  //     accessToken = null;
  //     _storage.deleteAll();
  //     return false;
  //   }
  // }
}
