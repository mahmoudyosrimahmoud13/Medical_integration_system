import 'package:dio/dio.dart';

class DioHelper {
  static final Dio _dio =
      Dio(BaseOptions(baseUrl: "http://healthhubserver.runasp.net/", headers: {
    'Accept': 'application/json',
  }));

  static Future<ResponseData> sendData({
    required String endPoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      var response = await _dio.post(endPoint, data: data);
      return ResponseData(
          isSuccess: !response.data['error'], response: response);
    } on DioException catch (ex) {
      print(ex.response?.data);
      return ResponseData(isSuccess: false, response: ex.response);
    }
  }

  static Future<ResponseData> sendFormData({
    required String endPoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      Response response = await _dio.post(
        endPoint,
        data: FormData.fromMap(data ?? {}),
      );
      return ResponseData(isSuccess: true, response: response);
    } on DioException catch (ex) {
      return ResponseData(isSuccess: false, response: ex.response);
    }
  }

  static Future<ResponseData> deleteData({
    required String endPoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      var response = await _dio.delete(endPoint, data: data);
      return ResponseData(isSuccess: true, response: response);
    } on DioException catch (ex) {
      return ResponseData(isSuccess: false, response: ex.response);
    }
  }

  static Future<ResponseData> getData({
    required String endPoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      var response = await _dio.get(endPoint, queryParameters: data);
      final lol = ResponseData(isSuccess: true, response: response);
      return lol;
    } on DioException catch (ex) {
      return ResponseData(isSuccess: false, response: ex.response);
    }
  }

  static Future<ResponseData> updateData({
    required String endPoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      var response = await _dio.put(endPoint, data: data);
      return ResponseData(isSuccess: true, response: response);
    } on DioException catch (ex) {
      return ResponseData(isSuccess: false, response: ex.response);
    }
  }
}

class ResponseData {
  late final bool isSuccess;
  late final Response? response;

  ResponseData({required this.isSuccess, this.response});
}
