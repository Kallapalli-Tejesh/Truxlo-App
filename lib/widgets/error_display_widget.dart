import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/error_provider.dart';
import '../core/errors/app_errors.dart';

class ErrorDisplayWidget extends ConsumerStatefulWidget {
  final Widget child;

  const ErrorDisplayWidget({required this.child, Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _ErrorDisplayWidgetState();
}

class _ErrorDisplayWidgetState extends ConsumerState<ErrorDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorState = ref.watch(errorProvider);

    // Animate error display
    if (errorState.isShowingError && errorState.currentError != null) {
      _animationController.forward();
      // Auto-dismiss after 6 seconds for non-critical errors
      if (errorState.currentError is! AuthenticationError) {
        Future.delayed(Duration(seconds: 6), () {
          if (mounted && errorState.isShowingError) {
            ref.read(errorProvider.notifier).clearError();
          }
        });
      }
    } else {
      _animationController.reverse();
    }

    return Stack(
      children: [
        widget.child,
        if (errorState.isShowingError && errorState.currentError != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildErrorBanner(context, errorState.currentError!),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, AppError error) {
    return Material(
      elevation: 8,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getErrorColor(error),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getErrorIcon(error),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getErrorTitle(error),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      ref.read(errorProvider.notifier).getUserFriendlyMessage(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => ref.read(errorProvider.notifier).clearError(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getErrorColor(AppError error) {
    if (error is NetworkError) return Colors.orange.shade600;
    if (error is AuthenticationError) return Colors.red.shade600;
    if (error is ValidationError) return Colors.amber.shade600;
    if (error is BusinessLogicError) return Colors.blue.shade600;
    if (error is DatabaseError) return Colors.purple.shade600;
    return Colors.red.shade600;
  }

  IconData _getErrorIcon(AppError error) {
    if (error is NetworkError) return Icons.wifi_off;
    if (error is AuthenticationError) return Icons.lock;
    if (error is ValidationError) return Icons.warning;
    if (error is BusinessLogicError) return Icons.info;
    if (error is DatabaseError) return Icons.storage;
    return Icons.error;
  }

  String _getErrorTitle(AppError error) {
    if (error is NetworkError) return 'Connection Issue';
    if (error is AuthenticationError) return 'Authentication Error';
    if (error is ValidationError) return 'Validation Error';
    if (error is BusinessLogicError) return 'Operation Failed';
    if (error is DatabaseError) return 'Data Error';
    return 'Error';
  }
} 