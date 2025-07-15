import 'package:flutter/material.dart';
import '../services/rate_limiter_service.dart';

class RateLimitStatusWidget extends StatefulWidget {
  final String userId;
  const RateLimitStatusWidget({required this.userId, super.key});
  @override
  State<RateLimitStatusWidget> createState() => _RateLimitStatusWidgetState();
}

class _RateLimitStatusWidgetState extends State<RateLimitStatusWidget> {
  Map<String, dynamic> _rateLimits = {};

  @override
  void initState() {
    super.initState();
    _loadRateLimits();
  }

  Future _loadRateLimits() async {
    final results = await Future.wait([
      RateLimiterService.checkGeneralRequest(widget.userId),
      RateLimiterService.checkLoginAttempt(widget.userId),
      RateLimiterService.checkJobApplication(widget.userId),
      RateLimiterService.checkJobPost(widget.userId),
    ]);
    setState(() {
      _rateLimits = {
        'General': results[0],
        'Login': results[1],
        'Job Application': results[2],
        'Job Post': results[3],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              const Text(
                'Rate Limit Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey[400]),
                onPressed: _loadRateLimits,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._rateLimits.entries.map((entry) => _buildRateLimitRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildRateLimitRow(String type, dynamic result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${result.remainingRequests}',
              style: TextStyle(
                color: result.allowed ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              result.allowed ? 'Available' : 'Limited',
              style: TextStyle(
                color: result.allowed ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 