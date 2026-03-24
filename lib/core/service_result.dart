class ServiceError {
  const ServiceError({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

class ServiceResult<T> {
  const ServiceResult._({
    this.data,
    this.error,
  });

  final T? data;
  final ServiceError? error;

  bool get isSuccess => error == null;

  static ServiceResult<T> ok<T>(T data) => ServiceResult._(data: data);

  static ServiceResult<T> fail<T>({
    String code = 'SERVICE_ERROR',
    required String message,
  }) =>
      ServiceResult._(
        error: ServiceError(code: code, message: message),
      );
}
