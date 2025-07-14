import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_errors.dart';

class ErrorHandlerService {
  static AppError handleError(dynamic error) {
    // Log error for debugging
    _logError(error);

    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is PostgrestException) {
      return _handleDatabaseError(error);
    } else if (error is AppError) {
      return error;
    } else {
      return _handleGenericError(error);
    }
  }

  static AuthenticationError _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return AuthenticationError(
          'Invalid email or password',
          code: error.statusCode,
          originalError: error,
        );
      case '422':
        return AuthenticationError(
          'Email already registered',
          code: error.statusCode,
          originalError: error,
        );
      case '429':
        return AuthenticationError(
          'Too many attempts. Please try again later',
          code: error.statusCode,
          originalError: error,
        );
      default:
        return AuthenticationError(
          'Authentication failed. Please try again',
          code: error.statusCode,
          originalError: error,
        );
    }
  }

  static DatabaseError _handleDatabaseError(PostgrestException error) {
    switch (error.code) {
      case '23505': // Unique constraint violation
        return DatabaseError(
          'This record already exists',
          code: error.code,
          originalError: error,
        );
      case '23503': // Foreign key constraint violation
        return DatabaseError(
          'Cannot perform this action due to related data',
          code: error.code,
          originalError: error,
        );
      case 'PGRST116': // No rows found
        return DatabaseError(
          'Record not found',
          code: error.code,
          originalError: error,
        );
      default:
        return DatabaseError(
          'Database operation failed. Please try again',
          code: error.code,
          originalError: error,
        );
    }
  }

  static AppError _handleGenericError(dynamic error) {
    if (error.toString().contains('SocketException') || 
        error.toString().contains('TimeoutException')) {
      return NetworkError(
        'No internet connection. Please check your network and try again',
        originalError: error,
      );
    }

    return UnknownError(
      'Something went wrong. Please try again',
      originalError: error,
    );
  }

  static void _logError(dynamic error) {
    if (kDebugMode) {
      developer.log(
        'Error occurred:  [${error.toString()}',
        name: 'ErrorHandler',
        error: error,
        stackTrace: error is Error ? error.stackTrace : StackTrace.current,
      );
    }
  }

  static String getUserFriendlyMessage(AppError error) {
    if (error is NetworkError) {
      return '🌐 ${error.message}';
    } else if (error is AuthenticationError) {
      return '🔐 ${error.message}';
    } else if (error is ValidationError) {
      return '⚠️ ${error.message}';
    } else if (error is BusinessLogicError) {
      return '💼 ${error.message}';
    } else if (error is DatabaseError) {
      return '💾 ${error.message}';
    } else {
      return '❌ ${error.message}';
    }
  }
} 