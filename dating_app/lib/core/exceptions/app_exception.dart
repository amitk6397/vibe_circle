class AppException implements Exception {
  final String message;
  final String code;
  final int? status;

  AppException(this.message, {this.code = 'request_failed', this.status});

  @override
  String toString() => message;
}

class ApiException extends AppException {
  ApiException(super.message, {super.code, super.status});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.status}) : super(code: 'network_error');
}

class TimeoutException extends NetworkException {
  TimeoutException(super.message) : super(status: 408);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(code: 'unauthorized', status: 401);
}

class ServerException extends ApiException {
  ServerException(super.message, {super.status}) : super(code: 'server_error');
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;
  ValidationException(super.message, {this.errors}) : super(code: 'validation_failed', status: 422);
}
