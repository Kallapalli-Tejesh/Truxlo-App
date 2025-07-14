abstract class AppError {
  final String message;
  final String? code;
  final dynamic originalError;

  AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkError extends AppError {
  NetworkError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class AuthenticationError extends AppError {
  AuthenticationError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ValidationError extends AppError {
  final Map fieldErrors;
  
  ValidationError(String message, this.fieldErrors, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class BusinessLogicError extends AppError {
  BusinessLogicError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class DatabaseError extends AppError {
  DatabaseError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class UnknownError extends AppError {
  UnknownError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
} 