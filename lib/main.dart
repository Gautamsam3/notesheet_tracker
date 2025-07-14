import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'providers/user_provider.dart';
import 'models/user_model.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'theme/app_theme.dart';
import 'services/pdf_upload_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 App starting up...');
  
  try {
    // Initialize Supabase
    debugPrint('📦 Initializing Supabase...');
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
    
    // Check if PDF storage bucket exists (don't create automatically)
    debugPrint('🗂️ Checking PDF storage bucket...');
    try {
      await PDFUploadService.ensureBucketExists();
      debugPrint('✅ PDF storage bucket ready');
    } catch (e) {
      debugPrint('⚠️ PDF storage bucket not found: $e');
      debugPrint('📝 Please create "notesheet-pdfs" bucket in Supabase dashboard');
      // Continue without failing - PDF uploads will be disabled until bucket exists
    }
    
    runApp(const MyApp());
    debugPrint('🏁 App launched successfully');
  } catch (error, stackTrace) {
    debugPrint('💀 Failed to initialize app: $error');
    debugPrint('Stack trace: $stackTrace');
    
    // Still try to run the app with error state
    runApp(ErrorApp(error: error.toString()));
  }
}

// Error app for when initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notesheet Tracker - Error',
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'Notesheet Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/signIn': (context) => const SignInScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/emailVerification': (context) => const EmailVerificationScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget? _currentScreen;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        debugPrint('🔄 AuthWrapper: isLoading=${userProvider.isLoading}, isLoggedIn=${userProvider.isLoggedIn}, error=${userProvider.error}');
        
        // Don't rebuild if we're still loading and the current screen is not a loading screen
        if (userProvider.isLoading) {
          debugPrint('⏳ AuthWrapper: User provider is loading...');
          final loadingScreen = const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
          _currentScreen = loadingScreen;
          return loadingScreen;
        }

        // Check if user has error (like missing profile or email not confirmed)
        if (userProvider.error != null) {
          if (userProvider.error!.contains('profile not found')) {
            debugPrint('🔧 Profile error detected, redirecting to sign-in');
            _currentScreen = const SignInScreen();
            return const SignInScreen();
          } else if (userProvider.error!.contains('confirm your account') || 
                     userProvider.error!.contains('Email not confirmed')) {
            debugPrint('📧 Email not confirmed, showing verification screen');
            _currentScreen = const EmailVerificationScreen();
            return const EmailVerificationScreen();
          }
        }

        if (userProvider.isLoggedIn && userProvider.currentUser != null) {
          final user = userProvider.currentUser!;
          debugPrint('👤 AuthWrapper: User is logged in - ${user.name} (${user.email})');
          debugPrint('🔑 AuthWrapper: User role: ${user.role?.name ?? 'null'}');
          debugPrint('📊 AuthWrapper: User permissions: requester=${user.isRequester}, reviewer=${user.isReviewer}, admin=${user.isAdmin}');
          
          // Check email verification first
          final supabaseUser = userProvider.authService.currentUser;
          if (supabaseUser != null && supabaseUser.emailConfirmedAt == null) {
            debugPrint('📧 User email not verified, showing verification screen');
            _currentScreen = const EmailVerificationScreen();
            return _currentScreen!;
          }
          
          // Check if user has a role assigned
          if (user.isPendingApproval) {
            debugPrint('⏳ User awaiting admin approval, showing pending screen');
            _currentScreen = const PendingApprovalScreen();
            return _currentScreen!;
          }
          
          // Add null check for role
          if (user.role == null) {
            debugPrint('⚠️ User role is null, showing pending approval screen');
            _currentScreen = const PendingApprovalScreen();
            return _currentScreen!;
          }
          
          // Route to appropriate dashboard based on role
          debugPrint('🎯 AuthWrapper: Routing user to dashboard based on role: ${user.role!.name}');
          Widget targetScreen;
          switch (user.role!) {
            case UserRole.admin:
              debugPrint('👑 Admin user logged in, showing admin dashboard');
              targetScreen = const AdminDashboard();
              break;
            case UserRole.requester:
            case UserRole.reviewer:
              debugPrint('✅ User logged in with role ${user.role!.name}, showing dashboard');
              targetScreen = const DashboardScreen();
              break;
          }
          
          // Only update if the screen has actually changed
          if (_currentScreen.runtimeType != targetScreen.runtimeType) {
            debugPrint('📱 AuthWrapper: Screen changed to ${targetScreen.runtimeType}');
            _currentScreen = targetScreen;
          }
          return _currentScreen!;
        }

        debugPrint('🚪 AuthWrapper: No user logged in, showing sign in screen');
        _currentScreen = const SignInScreen();
        return _currentScreen!;
      },
    );
  }
}
