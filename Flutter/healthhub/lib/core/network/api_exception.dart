import 'package:dio/dio.dart';

/// Every network or server problem ends up as an [ApiException] with a message
/// that is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  factory ApiException.fromDio(DioException e) {
    final fromBody = messageFromBody(e.response?.data);
    return ApiException(fromBody ?? _fallback(e), statusCode: e.response?.statusCode);
  }

  /// FastAPI answers errors as {"detail": "text"} or, for validation errors,
  /// {"detail": [{"loc": [..., "field"], "msg": "..."}]}.
  static String? messageFromBody(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        final msg = first['msg'].toString().replaceFirst('Value error, ', '');
        final loc = first['loc'];
        final field = loc is List && loc.isNotEmpty ? loc.last.toString() : null;
        return field == null || field == 'body' ? msg : '${_pretty(field)}: $msg';
      }
    }
    return null;
  }

  static String _pretty(String field) => field.replaceAll('_', ' ');

  static String _fallback(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long. Please try again.';
      case DioExceptionType.connectionError:
        return "Can't reach the server. Check your internet connection.";
      default:
        final code = e.response?.statusCode;
        if (code == 401) return 'Please log in again.';
        if (code == 403) return "You don't have access to this.";
        if (code == 404) return 'Not found.';
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => message;
}
