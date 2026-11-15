import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// A file picked by the user, as bytes so it works on mobile, desktop and web.
class UploadFile {
  const UploadFile({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// The only way features talk to the server. Tests replace it with a fake.
abstract class ApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? query});
  Future<dynamic> post(String path, {Object? body});
  Future<dynamic> put(String path, {Object? body});
  Future<dynamic> delete(String path);

  /// Multipart upload. [files] maps a form field name to one or more files.
  Future<dynamic> upload(
    String path, {
    Map<String, dynamic> fields = const {},
    Map<String, List<UploadFile>> files = const {},
    String method = 'POST',
  });
}

class DioApiClient implements ApiClient {
  DioApiClient({required String baseUrl, required TokenStorage tokens, void Function()? onUnauthorized, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      // The token is read on every request, so a fresh login is used right away.
      onRequest: (options, handler) {
        final token = tokens.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && tokens.token != null) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: _clean(query)));

  @override
  Future<dynamic> post(String path, {Object? body}) => _run(() => _dio.post(path, data: body));

  @override
  Future<dynamic> put(String path, {Object? body}) => _run(() => _dio.put(path, data: body));

  @override
  Future<dynamic> delete(String path) => _run(() => _dio.delete(path));

  @override
  Future<dynamic> upload(
    String path, {
    Map<String, dynamic> fields = const {},
    Map<String, List<UploadFile>> files = const {},
    String method = 'POST',
  }) {
    final form = FormData();
    fields.forEach((key, value) {
      if (value != null) form.fields.add(MapEntry(key, value.toString()));
    });
    files.forEach((key, list) {
      for (final f in list) {
        form.files.add(MapEntry(key, MultipartFile.fromBytes(f.bytes, filename: f.name)));
      }
    });
    return _run(() => _dio.request(path, data: form, options: Options(method: method)));
  }

  /// Drops null and empty values so the server sees only real filters.
  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return Map.fromEntries(query.entries.where((e) => e.value != null && e.value.toString().isNotEmpty));
  }
}
