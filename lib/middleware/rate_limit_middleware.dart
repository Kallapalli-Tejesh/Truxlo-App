import 'package:flutter/material.dart';
import '../services/rate_limiter_service.dart';
import '../core/errors/app_errors.dart';

class RateLimitMiddleware {
  /// Wrap API calls with rate limiting
  static Future withRateLimit(
    String userId,
    String operationType,
    Future Function() operation, {
    bool showUserFeedback = true,
    BuildContext? context,
  }) async {
    RateLimitResult rateLimitResult;
    // Check rate limit based on operation type
    switch (operationType) {
      case 'login':
        rateLimitResult = await RateLimiterService.checkLoginAttempt(userId);
        break;
      case 'job_application':
        rateLimitResult = await RateLimiterService.checkJobApplication(userId);
        break;
      case 'job_post':
        rateLimitResult = await RateLimiterService.checkJobPost(userId);
        break;
      default:
        rateLimitResult = await RateLimiterService.checkGeneralRequest(userId);
    }
    // If rate limit exceeded, throw error
    if (!rateLimitResult.allowed) {
      if (showUserFeedback && context != null) {
        _showRateLimitError(context, rateLimitResult);
      }
      throw BusinessLogicError(
        rateLimitResult.message,
        code: 'RATE_LIMIT_EXCEEDED',
      );
    }
    try {
      // Execute the operation
      final result = await operation();
      // Record successful request
      await RateLimiterService.recordRequest(userId, operationType);
      return result;
    } catch (e) {
      // Don't record failed requests (except for login attempts)
      if (operationType == 'login') {
        await RateLimiterService.recordRequest(userId, operationType);
      }
      rethrow;
    }
  }

  static void _showRateLimitError(BuildContext context, RateLimitResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.speed, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate Limit Exceeded',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    result.message,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }
} 