import 'dart:io';

import 'package:dio/dio.dart';

import 'config.dart';

/// Thrown for any failed request; screens catch this and show `message` directly —
/// it's already a short, user-facing string (the backend sends clean messages, see
/// gym-backend/app/main.py's exception handlers).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// One shared Dio instance for the whole app. Every admin request automatically gets the
/// current Firebase ID token attached — screens never touch headers directly.
class ApiClient {
  final Dio _dio;
  final Future<String?> Function() _tokenProvider;

  ApiClient({required Future<String?> Function() tokenProvider})
      : _tokenProvider = tokenProvider,
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenProvider();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) => _run(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) => _run(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path) => _run(() => _dio.delete(path));

  /// multipart image upload -> returns { "url": ..., "public_id": ... }
  Future<dynamic> uploadImage(String folder, File file) => _run(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
        });
        return _dio.post('/admin/uploads/$folder', data: form);
      });

  Future<dynamic> _run(Future<Response> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  String _extractMessage(DioException e) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your internet connection.';
    }
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return 'Something went wrong (${e.response?.statusCode ?? 'network error'}).';
  }
}
