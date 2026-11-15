import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/network/api_exception.dart';

void main() {
  DioException dioError(int? status, dynamic body, [DioExceptionType type = DioExceptionType.badResponse]) {
    final options = RequestOptions(path: '/x');
    return DioException(
      requestOptions: options,
      type: type,
      response: status == null ? null : Response(requestOptions: options, statusCode: status, data: body),
    );
  }

  test('uses the FastAPI detail string', () {
    final e = ApiException.fromDio(dioError(400, {'detail': 'Choose The Appropriate Day'}));
    expect(e.message, 'Choose The Appropriate Day');
    expect(e.statusCode, 400);
  });

  test('turns a validation error into "field: message"', () {
    final e = ApiException.fromDio(dioError(422, {
      'detail': [
        {'loc': ['body', 'national_id'], 'msg': 'Value error, National ID Required (14 digits)'}
      ]
    }));
    expect(e.message, 'national id: National ID Required (14 digits)');
  });

  test('friendly fallbacks', () {
    expect(ApiException.fromDio(dioError(null, null, DioExceptionType.connectionError)).message, contains('internet'));
    expect(ApiException.fromDio(dioError(null, null, DioExceptionType.receiveTimeout)).message, contains('too long'));
    expect(ApiException.fromDio(dioError(401, 'x')).isUnauthorized, isTrue);
    expect(ApiException.fromDio(dioError(404, 'x')).isNotFound, isTrue);
  });
}
