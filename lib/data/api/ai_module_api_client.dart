import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';

/// Client HTTP dédié au backend Flask AI, volontairement séparé de l'API Ma3ak.
class AiModuleApiClient {
  AiModuleApiClient({Dio? dio, String? baseUrl})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? AppConfig.aiModuleBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      this.dio.interceptors.add(
        // Les payloads image/base64 peuvent être énormes en mode live.
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }
  }

  final Dio dio;

  Future<Response<Map<String, dynamic>>> getHealth() {
    return dio.get<Map<String, dynamic>>(
      '/health',
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> listModels() {
    return dio.get<Map<String, dynamic>>(
      '/models',
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> predictJson(
    String modelName,
    Map<String, dynamic> payload, {
    Duration sendTimeout = const Duration(seconds: 25),
    Duration receiveTimeout = const Duration(seconds: 45),
  }) {
    return dio.post<Map<String, dynamic>>(
      '/$modelName/predict',
      data: payload,
      options: Options(sendTimeout: sendTimeout, receiveTimeout: receiveTimeout),
    );
  }

  Future<Response<Map<String, dynamic>>> predictMultipart(
    String modelName,
    FormData payload, {
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 60),
  }) {
    return dio.post<Map<String, dynamic>>(
      '/$modelName/predict',
      data: payload,
      options: Options(sendTimeout: sendTimeout, receiveTimeout: receiveTimeout),
    );
  }

  Future<Response<Map<String, dynamic>>> postStt(FormData formData) {
    return dio.post<Map<String, dynamic>>(
      '/stt',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postTts(Map<String, dynamic> json) {
    return dio.post<Map<String, dynamic>>('/tts', data: json);
  }

  Future<Response<Map<String, dynamic>>> postAirClick(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>('/air-click', data: json);
  }

  Future<Response<Map<String, dynamic>>> postDwellSelect(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/dwell-select',
      data: json,
      options: Options(
        sendTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postDwellReset(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/dwell-reset',
      data: json,
      options: Options(
        sendTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postAdapt(Map<String, dynamic> json) {
    return dio.post<Map<String, dynamic>>(
      '/adapt',
      data: json,
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postIntent(Map<String, dynamic> json) {
    return dio.post<Map<String, dynamic>>(
      '/intent',
      data: json,
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postScreenSummary(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/screen-summary',
      data: json,
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
  }
}
