import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/user_provider.dart';

class DriverHomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    if (userState.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (userState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error:  [${userState.error}'),
              ElevatedButton(
                onPressed: () => ref.read(userProvider.notifier).loadUserProfile(),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
      ),
      body: Column(
        children: [
          if (userState.profile != null)
            Text('Welcome, ${userState.profile!['name']}'),
          // Your existing job list and other widgets...
        ],
      ),
    );
  }
}
