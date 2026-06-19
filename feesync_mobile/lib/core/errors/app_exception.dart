sealed class AppException implements Exception {
  final String message;
  final String? originalError;

  const AppException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String? originalError]) 
      : super('A network error occurred. Please check your connection.', originalError);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.originalError]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.originalError]);
}

class UnknownException extends AppException {
  const UnknownException([String? originalError]) 
      : super('An unknown error occurred.', originalError);
}
