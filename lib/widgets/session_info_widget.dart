import 'package:flutter/material.dart';
import '../services/session_service.dart';

class SessionInfoWidget extends StatefulWidget {
  const SessionInfoWidget({super.key});
  @override
  State<SessionInfoWidget> createState() => _SessionInfoWidgetState();
}

class _SessionInfoWidgetState extends State<SessionInfoWidget> {
  SessionInfo? _sessionInfo;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    final info = await SessionService.getSessionInfo();
    setState(() {
      _sessionInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionInfo == null) {
      return const CircularProgressIndicator();
    }
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
          const Text(
            'Session Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Status',
            _sessionInfo!.isValid ? 'Active' : 'Expired',
            _sessionInfo!.isValid ? Colors.green : Colors.red,
          ),
          if (_sessionInfo!.sessionStart != null)
            _buildInfoRow(
              'Session Started',
              _formatDateTime(_sessionInfo!.sessionStart!),
              Colors.grey[400]!,
            ),
          if (_sessionInfo!.lastActivity != null)
            _buildInfoRow(
              'Last Activity',
              _formatDateTime(_sessionInfo!.lastActivity!),
              Colors.grey[400]!,
            ),
          if (_sessionInfo!.timeRemaining != null)
            _buildInfoRow(
              'Time Remaining',
              _sessionInfo!.timeRemainingFormatted,
              _getTimeRemainingColor(_sessionInfo!.timeRemaining!),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await SessionService.updateActivity();
                  await _loadSessionInfo();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session extended'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                child: const Text('Extend Session'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  await SessionService.forceLogout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getTimeRemainingColor(Duration timeRemaining) {
    if (timeRemaining.inMinutes <= 5) {
      return Colors.orange;
    } else if (timeRemaining.inMinutes <= 60) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
} 