import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_service.dart';

class SessionManagementWidget extends ConsumerStatefulWidget {
  final Widget child;

  const SessionManagementWidget({required this.child, super.key});

  @override
  ConsumerState createState() => _SessionManagementWidgetState();
}

class _SessionManagementWidgetState extends ConsumerState<SessionManagementWidget> {
  late Stream _sessionStream;

  @override
  void initState() {
    super.initState();
    _sessionStream = SessionService.sessionStatusStream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _sessionStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          switch (snapshot.data!) {
            case SessionStatus.warning:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showSessionWarning();
              });
              break;
            case SessionStatus.expired:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleSessionExpired();
              });
              break;
            case SessionStatus.active:
              // Session is active, no action needed
              break;
          }
        }
        return widget.child;
      },
    );
  }

  void _showSessionWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'Session Expiring Soon',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Your session will expire in 5 minutes due to inactivity. Would you like to extend your session?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SessionService.forceLogout();
            },
            child: const Text('Logout Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SessionService.updateActivity();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session extended successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Extend Session'),
          ),
        ],
      ),
    );
  }

  void _handleSessionExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Session Expired',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Your session has expired due to inactivity. Please log in again to continue.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }
} 