/// Base class for application failures
class AppFailure implements Exception {
  final String message;
  final int? statusCode;

  AppFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thrown when the user's token is invalid or expired
class UnauthorizedFailure extends AppFailure {
  UnauthorizedFailure([String message = 'Token inválido o expirado'])
      : super(message, statusCode: 401);
}

/// Thrown when the server returns a validation error
class ValidationFailure extends AppFailure {
  final Map<String, dynamic>? errors;

  ValidationFailure(String message, {this.errors})
      : super(message, statusCode: 422);
}

/// Thrown when there is a network connectivity issue
class NetworkFailure extends AppFailure {
  NetworkFailure([String message = 'Sin conexión a internet'])
      : super(message);
}

/// Thrown when the server returns an unexpected error
class ServerFailure extends AppFailure {
  ServerFailure([String message = 'Error en el servidor'])
      : super(message, statusCode: 500);
}
