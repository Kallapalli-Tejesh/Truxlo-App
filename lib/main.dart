import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/driver/presentation/pages/driver_home_page.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    // Fallback to default values or throw error
  }

  // Verify critical environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing required Supabase environment variables');
  }

  // Initialize Supabase with error handling
  try {
  await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode, // Only enable debug in development
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    throw Exception('Failed to initialize Supabase: $e');
  }

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(userProvider, (previous, next) {
      // Handle user state changes if needed
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUserProfile();
    });
    return MaterialApp(
      title: 'Truxlo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: Consumer(
        builder: (context, ref, child) {
          final userState = ref.watch(userProvider);
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser == null) {
            return LoginPage();
          }
          final userRole = userState.profile?['role']?.toString().toLowerCase();
          if (userRole == 'driver') {
            return DriverHomePage();
          }
          return HomePage();
        },
      ),
      routes: {
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Truxlo')),
      body: const Center(child: Text('Welcome to Truxlo')),
    );
  }
}
