import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/app_errors.dart';
import '../services/error_handler_service.dart';

class ErrorState {
  final AppError? currentError;
  final List errorHistory;
  final bool isShowingError;

  ErrorState({
    this.currentError,
    this.errorHistory = const [],
    this.isShowingError = false,
  });

  ErrorState copyWith({
    AppError? currentError,
    List? errorHistory,
    bool? isShowingError,
  }) {
    return ErrorState(
      currentError: currentError,
      errorHistory: errorHistory ?? this.errorHistory,
      isShowingError: isShowingError ?? this.isShowingError,
    );
  }
}

class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(ErrorState());

  void showError(dynamic error) {
    final appError = ErrorHandlerService.handleError(error);
    final updatedHistory = [...state.errorHistory, appError];
    
    state = state.copyWith(
      currentError: appError,
      errorHistory: updatedHistory,
      isShowingError: true,
    );
  }

  void clearError() {
    state = state.copyWith(
      currentError: null,
      isShowingError: false,
    );
  }

  void clearAllErrors() {
    state = ErrorState();
  }

  String getUserFriendlyMessage() {
    if (state.currentError != null) {
      return ErrorHandlerService.getUserFriendlyMessage(state.currentError!);
    }
    return '';
  }
}

final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
}); 