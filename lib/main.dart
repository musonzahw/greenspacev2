import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/landing_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/event_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  

  // Load environment variables
  if (kIsWeb) {
    // For web, we'll use the window.env object defined in index.html
    debugPrint('Running in web mode, using window.env for configuration');
  } else {
    // For mobile/desktop, try to load .env from assets
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }
  }
  
  // Initialize Supabase with correct URL and anon key
  final supabaseUrl = kIsWeb 
      ? (const String.fromEnvironment('SUPABASE_URL', 
          defaultValue: 'https://dsmnfckybesiextyojvb.supabase.co'))
      : (dotenv.env['SUPABASE_URL'] ?? 'https://dsmnfckybesiextyojvb.supabase.co');
  
  final supabaseAnonKey = kIsWeb
      ? (const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzbW5mY2t5YmVzaWV4dHlvanZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4ODgyMDAsImV4cCI6MjA3NjQ2NDIwMH0.qJ3-EBZ3V8kFG2EeHj6FBzxsEDNfcQ2QQz_udhyYpvk'))
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzbW5mY2t5YmVzaWV4dHlvanZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4ODgyMDAsImV4cCI6MjA3NjQ2NDIwMH0.qJ3-EBZ3V8kFG2EeHj6FBzxsEDNfcQ2QQz_udhyYpvk');

  debugPrint('Initializing Supabase with URL: $supabaseUrl');
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Create the theme provider
  final themeProvider = ThemeProvider();
  
  // Initialize the theme
  await themeProvider.loadThemePreference();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const AppInitializer(),
    ),
  );
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate app initialization (e.g., loading user data, preferences, etc.)
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to initialize app: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoadingScreen(
          loadingText: 'Preparing Greenspace...',
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 20),
                  Text(
                    'Initialization Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                        _initializeApp();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'GreenSpace',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(context),
          darkTheme: themeProvider.getTheme(context),
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const LandingScreen(),
            '/auth': (context) => const AuthScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }

  Widget _buildAuthWrapper(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          );
        }

        // Check the current auth state
        final session = Supabase.instance.client.auth.currentSession;
        
        // If we have a valid session, user is logged in
        if (session != null) {
          // Use a post-frame callback to navigate to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
          // Return a loading screen while navigating
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          );
        }

        // If no session, show landing screen (handled by initialRoute)
        return const SizedBox.shrink();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Greenspace',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(context),
          darkTheme: themeProvider.getTheme(context),
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
