enum ApiStatus { loading, success, error, empty }

class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? message;
  final String? code;
  final int? statusCode;

  ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.code,
    this.statusCode,
  });

  factory ApiResponse.loading() => ApiResponse(status: ApiStatus.loading);

  factory ApiResponse.success(T data) => ApiResponse(status: ApiStatus.success, data: data);

  factory ApiResponse.error(String message, {String? code, int? statusCode}) => ApiResponse(
        status: ApiStatus.error,
        message: message,
        code: code,
        statusCode: statusCode,
      );

  factory ApiResponse.empty() => ApiResponse(status: ApiStatus.empty);

  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
  bool get isEmpty => status == ApiStatus.empty;
}
