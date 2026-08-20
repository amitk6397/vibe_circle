import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_urls.dart';
import '../exceptions/app_exception.dart';
import '../storage/local_storage.dart';

class NetworkApiService {
  late final Dio _dio;

  NetworkApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiUrls.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Setup Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await LocalStorage.instance.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If Unauthorized (401) and not a refresh call or already retried
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != '/auth/refresh' &&
              error.requestOptions.extra['retry'] != true) {
            
            error.requestOptions.extra['retry'] = true;
            try {
              final refreshToken = await LocalStorage.instance.getRefreshToken();
              if (refreshToken != null) {
                // Call token refresh using a separate Dio client to avoid loops
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: ApiUrls.baseUrl,
                    headers: {'Accept': 'application/json'},
                  ),
                );
                
                final response = await refreshDio.post('/auth/refresh', data: {
                  'refresh_token': refreshToken,
                });
                
                final newAccess = response.data['access_token'] as String;
                final newRefresh = response.data['refresh_token'] as String;
                
                // Save new tokens
                await LocalStorage.instance.saveTokens(newAccess, newRefresh);
                
                // Retry the original request
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                final clonedResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(clonedResponse);
              }
            } catch (_) {
              // Token refresh failed - logout user
              await LocalStorage.instance.clearAll();
              return handler.next(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  error: UnauthorizedException('Session expired. Please log in again.'),
                  type: error.type,
                ),
              );
            }
          }

          // Map other Dio errors to AppExceptions
          final appException = _handleDioError(error);
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: appException,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  static final NetworkApiService instance = NetworkApiService._();

  // GET
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : _handleDioError(e);
    }
  }

  // POST
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : _handleDioError(e);
    }
  }

  // PUT
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : _handleDioError(e);
    }
  }

  // PATCH
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : _handleDioError(e);
    }
  }

  // DELETE
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : _handleDioError(e);
    }
  }

  // MULTIPART / FILE UPLOAD
  Future<Response> uploadFile(String path, File file, {String fieldName = 'file'}) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      return await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : _handleDioError(e);
    }
  }

  // Exception Converter
  static AppException _handleDioError(DioException error) {
    if (error.error is AppException) {
      return error.error as AppException;
    }

    final int? statusCode = error.response?.statusCode;
    final Map<String, dynamic>? data = error.response?.data is Map ? error.response?.data as Map<String, dynamic> : null;
    final dynamic detail = data?['error'];
    final String serverMessage = detail is Map ? detail['message'] ?? '' : detail?.toString() ?? '';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('The request timed out. Please check your internet connection.');
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return UnauthorizedException(serverMessage.isNotEmpty ? serverMessage : 'Unauthorized access.');
        } else if (statusCode == 422) {
          final validationErrors = (data != null && data['errors'] is Map) ? data['errors'] as Map<String, dynamic> : null;
          return ValidationException(
            serverMessage.isNotEmpty ? serverMessage : 'Validation failed.',
            errors: validationErrors,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException('Internal Server Error. Please try again later.', status: statusCode);
        }
        return ApiException(
          serverMessage.isNotEmpty ? serverMessage : 'Request failed with status code $statusCode.',
          code: detail is Map ? detail['code'] ?? 'request_failed' : 'request_failed',
          status: statusCode,
        );
      case DioExceptionType.connectionError:
      default:
        return NetworkException(
          'Unable to connect to VibeCircle. Check that the backend is running and that your device is connected.',
        );
    }
  }
}
