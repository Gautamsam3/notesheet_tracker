import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mqxjdqnbdbmuhucmiomf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xeGpkcW5iZGJtdWh1Y21pb21mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwMjIxNDYsImV4cCI6MjA2NzU5ODE0Nn0.gLr1K38Tm3HDLv16XGkrqlEjNcd-u_NnhCL687vr6zE',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notesheet Tracker App', // Updated app title
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define a custom input decoration theme for consistency
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50], // Light background for input fields
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              8,
            ), // Slightly less rounded corners
            borderSide: BorderSide.none, // No border by default
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ), // Subtle border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.blue.shade600,
              width: 2,
            ), // Blue focus border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red.shade600, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red.shade600, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIconColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return Colors.blue.shade600; // Blue icon when focused
            }
            return Colors.grey[600]!; // Grey icon when not focused
          }),
          suffixIconColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return Colors.blue.shade600; // Blue icon when focused
            }
            return Colors.grey[600]!; // Grey icon when not focused
          }),
        ),
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return DashboardScreen();
          }
        }
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ADD THIS LINE: Perform the actual sign-in with email and password
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // If sign in successful, user will be redirected automatically
      // by the AuthWrapper
    } on AuthException catch (error) {
      String errorMessage;
      if (error.message.contains('email not confirmed') ||
          error.message.contains('Email not confirmed')) {
        // Show dialog with resend option
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Email Not Confirmed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.email_outlined, size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Please check your email and click the confirmation link to verify your account.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _emailController.text.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await Supabase.instance.client.auth.resend(
                        type: OtpType.signup,
                        email: _emailController.text.trim(),
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Confirmation email resent! Check your inbox.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to resend email'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Resend Email'),
                ),
              ],
            );
          },
        );
        return;
      } else if (error.message.contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else {
        errorMessage = error.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if it's a wide screen (e.g., tablet or desktop)
          bool isWideScreen =
              constraints.maxWidth > 700; // You can adjust this threshold

          return Container(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor, // Use theme's background color
            child: SafeArea(
              child: isWideScreen
                  ? Row(
                      children: [
                        // Left side: App Name and image
                        Expanded(
                          flex: 1, // Takes 1/3 of the width
                          child: Container(
                            color: Theme.of(
                              context,
                            ).primaryColor, // Primary blue color
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Add your image here
                                  // Example: Image.asset('assets/images/your_light_image.png', height: 100),
                                  // Make sure the image asset is declared in pubspec.yaml and exists at the path.
                                  // Example:
                                  /*
                                  Image.asset(
                                    'assets/images/your_light_image.png', // Replace with your image path
                                    height: 120, // Adjust height as needed
                                    width: 120, // Adjust width as needed
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(height: 24), // Space between image and text
                                  */
                                  Text(
                                    'Notesheet Tracker App', // App Name
                                    style: TextStyle(
                                      fontSize: 32, // Larger font size
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .white, // White text on blue background
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Streamline Your Document Workflow', // Tagline
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors
                                          .white70, // Slightly transparent white
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Right side: Sign-in Form
                        Expanded(
                          flex: 2, // Takes 2/3 of the width
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(32.0),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: _buildLoginForm(
                                      context,
                                      isWideScreen,
                                    ), // Pass isWideScreen
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      // Mobile portrait view (original single column)
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(32.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: _buildLoginForm(
                                context,
                                isWideScreen,
                              ), // Pass isWideScreen
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  // Extracted Login Form Widget
  Widget _buildLoginForm(BuildContext context, bool isWideScreen) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Conditionally show app name/logo for non-wide screen
          if (!isWideScreen) ...[
            // Only show for non-wide screen
            Text(
              'Notesheet Tracker App', // App Name
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
          ],

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Log in',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(height: 24),

          // User ID Field (matches image aesthetic)
          TextFormField(
            controller: _emailController,
            keyboardType:
                TextInputType.emailAddress, // Keep email for functionality
            decoration: InputDecoration(
              labelText: 'User ID', // Changed label
              prefixIcon: Icon(Icons.person_outline), // Changed icon
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your User ID';
              }
              // Keeping email validation for actual Supabase login
              if (!RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Implement forgot password logic
              },
              child: Text(
                'Forgot your password?',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).primaryColor, // Use primary color for links
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor, // Use primary color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // Less rounded corners
                ),
                elevation: 5, // Increased elevation for button prominence
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Login', // Changed to Login
                      style: TextStyle(
                        fontSize: 18, // Slightly larger font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16),

          // Sign Up Link (kept for functionality, though not prominent in image)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),
              );
            },
            child: Text(
              'Don\'t have an account? Sign up',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).primaryColor, // Use primary color for links
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'name': _nameController.text.trim()},
      );

      if (response.user != null) {
        // Save additional user info to profiles table
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': response.user!.id,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Profile might already exist, ignore error
          print('Profile creation error (might already exist): $e');
        }

        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          // Email confirmation required
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Check Your Email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'We\'ve sent a confirmation email to:',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _emailController.text.trim(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Please click the link in the email to verify your account before signing in.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context); // Go back to login
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Email already confirmed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account created successfully! You can now sign in.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } on AuthException catch (error) {
      String errorMessage = error.message;
      if (error.message.contains('already registered')) {
        errorMessage =
            'This email is already registered. Please sign in instead.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 700;

          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: isWideScreen
                  ? Row(
                      children: [
                        // Left side: App Name only (no logo)
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Theme.of(context).primaryColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Notesheet Tracker App',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Organize Your Workflows', // Tagline for signup
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Right side: Sign-up Form
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(32.0),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(_slideAnimation.value, 0),
                                  end: Offset.zero,
                                ).animate(_animationController),
                                child: Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: _buildSignUpForm(
                                      context,
                                      isWideScreen,
                                    ), // Extracted form
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      // Mobile portrait view
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(32.0),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(_slideAnimation.value, 0),
                            end: Offset.zero,
                          ).animate(_animationController),
                          child: Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: _buildSignUpForm(
                                context,
                                isWideScreen,
                              ), // Reusing form method
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  // Extracted Sign Up Form Widget
  Widget _buildSignUpForm(BuildContext context, bool isWideScreen) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isWideScreen) ...[
            // Only show for non-wide screen
            Text(
              'Notesheet Tracker App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
          ],

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          SizedBox(height: 24),

          // Sign Up Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor, // Consistent button color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Consistent rounding
                ),
                elevation: 5,
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16),

          // Sign In Link
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Already have an account? Sign in',
              style: TextStyle(
                color: Theme.of(context).primaryColor, // Consistent color
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedFileName;
  String?
  selectedFilePath; // This path is local, not for Supabase Storage directly
  String? selectedReviewer;
  final TextEditingController _notesController = TextEditingController();
  String? userEmail;
  bool isReviewer = false;
  String?
  currentReviewerName; // To store the full name of the logged-in reviewer

  // In-memory storage for submissions (will be replaced by fetching from Supabase)
  List<Map<String, dynamic>> submissions = [];

  final List<String> initialReviewers = [
    'John Smith - Senior Manager',
    'Sarah Johnson - Team Lead',
    'Mike Davis - Project Manager',
    'Emily Brown - Quality Assurance',
    'David Wilson - Technical Lead',
  ];

  final List<String> initialReviewerEmails = [
    'johnsmith@gmail.com',
    'sarahjohnson@gmail.com',
    'mikedavis@gmail.com',
    'emilybrown@gmail.com',
    'davidwilson@gmail.com',
  ];

  // Define HOD separately
  final String hodName = 'Dr. Alex Lee - Head of Department';
  final String hodEmail = 'hod@gmail.com';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchSubmissions(); // Fetch submissions when the dashboard loads
  }

  void _getCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
        // Check if user is an initial reviewer
        int initialReviewerIndex = initialReviewerEmails.indexWhere(
          (email) => userEmail!.toLowerCase() == email.toLowerCase(),
        );

        if (initialReviewerIndex != -1) {
          isReviewer = true;
          currentReviewerName = initialReviewers[initialReviewerIndex];
        } else if (userEmail!.toLowerCase() == hodEmail.toLowerCase()) {
          isReviewer = true; // HOD is also a reviewer
          currentReviewerName = hodName;
        } else {
          isReviewer = false;
          currentReviewerName = null;
        }
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        selectedFilePath = result.files.single.path;
      });
    }
  }

  Future<void> _submitDocument() async {
    if (selectedFileName == null || selectedReviewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a document and reviewer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Insert into Supabase 'documents' table
      final response = await Supabase.instance.client.from('documents').insert({
        'document_name': selectedFileName!,
        'reviewer': selectedReviewer!,
        'status': 'Under Review',
        'submission_date': DateTime.now().toIso8601String().split('T')[0],
        'submitter_email': userEmail!,
        'notes': _notesController.text.trim(),
        // If you were storing the actual file in Supabase Storage,
        // you'd upload it here and save the storage path.
        // For now, we're just saving metadata.
      }).select(); // Use .select() to get the inserted data back

      if (response != null && response.isNotEmpty) {
        // Add the newly submitted document to the in-memory list and refresh
        _fetchSubmissions();

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Document submitted successfully for review!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to insert document into Supabase.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting document: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateDocumentStatus(
    String documentId,
    String currentDocumentStatus,
    String currentAssignedReviewer,
    String newDecisionStatus,
  ) async {
    try {
      String statusToUpdate;
      String? nextAssignedReviewer;

      final bool isCurrentUserHOD = currentReviewerName == hodName;
      final bool isDocumentCurrentlyAssignedToHOD =
          currentAssignedReviewer == hodName;

      if (isCurrentUserHOD) {
        // HOD is making the decision
        if (currentDocumentStatus != 'Forwarded to HOD' ||
            !isDocumentCurrentlyAssignedToHOD) {
          throw Exception(
            'HOD cannot update a document not assigned or forwarded to them.',
          );
        }
        statusToUpdate = newDecisionStatus; // 'Approved' or 'Needs Revision'
        nextAssignedReviewer = hodName; // Stays assigned to HOD as final point
      } else {
        // An initial reviewer is making the decision
        if (currentDocumentStatus != 'Under Review' ||
            currentAssignedReviewer != currentReviewerName) {
          throw Exception(
            'Not authorized to update this document or its not under your review.',
          );
        }

        if (newDecisionStatus == 'Approved') {
          // If approved by an initial reviewer, forward to HOD
          statusToUpdate = 'Forwarded to HOD';
          nextAssignedReviewer = hodName; // Assign to HOD
        } else {
          // newDecisionStatus == 'Needs Revision'
          // If rejected by an initial reviewer, it's final
          statusToUpdate = 'Needs Revision'; // Final status
          nextAssignedReviewer =
              currentReviewerName; // Stays assigned to current reviewer
        }
      }

      await Supabase.instance.client
          .from('documents')
          .update({'status': statusToUpdate, 'reviewer': nextAssignedReviewer})
          .eq('id', documentId);

      _fetchSubmissions(); // Refresh the local list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document status updated to: $statusToUpdate'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchSubmissions() async {
    try {
      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('documents')
          .select('*');
      setState(() {
        submissions = data.map((item) {
          return {
            'id': item['id'].toString(),
            'document': item['document_name'],
            'reviewer': item['reviewer'],
            'status': item['status'],
            'date': item['submission_date'],
            'statusColor': _getStatusColor(item['status']),
            'submitter': item['submitter_email'],
            'notes': item['notes'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching submissions: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      selectedFileName = null;
      selectedFilePath = null;
      selectedReviewer = null;
      _notesController.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Needs Revision':
        return Colors.red;
      case 'Under Review':
        return Colors.orange;
      case 'Forwarded to HOD':
        return Colors.purple; // New color for HOD review pending
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle;
      case 'Needs Revision':
        return Icons.error;
      case 'Under Review':
        return Icons.pending;
      case 'Forwarded to HOD':
        return Icons.send; // Icon for forwarded
      default:
        return Icons.help_outline;
    }
  }

  List<Map<String, dynamic>> _getFilteredSubmissions() {
    if (isReviewer) {
      // Means the logged in user is either an initial reviewer or HOD
      final bool isCurrentUserHOD = currentReviewerName == hodName;

      if (isCurrentUserHOD) {
        // HOD sees documents that are 'Forwarded to HOD' and assigned to them
        return submissions.where((sub) {
          return sub['reviewer'] == hodName &&
              sub['status'] == 'Forwarded to HOD';
        }).toList();
      } else {
        // Initial reviewers see documents 'Under Review' assigned to them
        return submissions.where((sub) {
          // Ensure it's not the HOD, but one of the other initial reviewers
          return sub['reviewer'] == currentReviewerName &&
              sub['status'] == 'Under Review';
        }).toList();
      }
    } else {
      // Regular users (submitters) see all their submissions
      return submissions.where((sub) => sub['submitter'] == userEmail).toList();
    }
  }

  int _getTotalSubmissions() {
    final filteredSubmissions = _getFilteredSubmissions();
    return filteredSubmissions.length;
  }

  int _getPendingReviews() {
    final filteredSubmissions = _getFilteredSubmissions();
    final bool isCurrentUserHOD = currentReviewerName == hodName;

    if (isCurrentUserHOD) {
      return filteredSubmissions
          .where((sub) => sub['status'] == 'Forwarded to HOD')
          .length;
    } else if (isReviewer) {
      return filteredSubmissions
          .where((sub) => sub['status'] == 'Under Review')
          .length;
    } else {
      // For regular users, pending means 'Under Review' or 'Forwarded to HOD'
      return filteredSubmissions
          .where(
            (sub) =>
                sub['status'] == 'Under Review' ||
                sub['status'] == 'Forwarded to HOD',
          )
          .length;
    }
  }

  int _getApprovedSubmissions() {
    final filteredSubmissions = _getFilteredSubmissions();
    return filteredSubmissions
        .where((sub) => sub['status'] == 'Approved')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserHOD = currentReviewerName == hodName;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          isCurrentUserHOD
              ? 'HOD Dashboard'
              : (isReviewer
                    ? 'Reviewer Dashboard'
                    : 'Document Review Dashboard'),
        ),
        backgroundColor: Theme.of(
          context,
        ).primaryColor, // Use theme primary color
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isReviewer)
            Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCurrentUserHOD ? 'HOD' : 'REVIEWER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'user',
                  enabled: false,
                  child: Text(
                    userEmail ?? 'User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Submissions',
                    _getTotalSubmissions().toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    isCurrentUserHOD ? 'Pending HOD Review' : 'Pending Reviews',
                    _getPendingReviews().toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Approved',
                    _getApprovedSubmissions().toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Submit Document Section (only for non-reviewers)
            if (!isReviewer) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Document for Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),

                      // File Selection
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              selectedFileName ?? 'No file selected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selectedFileName != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: Icon(Icons.attach_file),
                              label: Text('Select Document'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor, // Consistent color
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Reviewer Selection
                      DropdownButtonFormField<String>(
                        value: selectedReviewer,
                        decoration: InputDecoration(
                          labelText: 'Select Reviewer',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: initialReviewers.map((String reviewer) {
                          return DropdownMenuItem<String>(
                            value: reviewer,
                            child: Text(reviewer),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedReviewer = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          hintText:
                              'Add any additional context or requirements...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitDocument,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Submit for Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],

            // Submissions List
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUserHOD
                          ? 'Documents for HOD Review'
                          : (isReviewer
                                ? 'Your Assigned Documents'
                                : 'Your Submissions'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),

                    if (_getFilteredSubmissions().isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              isCurrentUserHOD
                                  ? 'No documents pending your review'
                                  : (isReviewer
                                        ? 'No documents assigned to you yet'
                                        : 'No submissions yet'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _getFilteredSubmissions().length,
                        itemBuilder: (context, index) {
                          final submission = _getFilteredSubmissions()[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: submission['statusColor'],
                                child: Icon(
                                  _getStatusIcon(submission['status']),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                submission['document'],
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reviewer: ${submission['reviewer']}'),
                                  Text('Date: ${submission['date']}'),
                                  if (isReviewer)
                                    Text(
                                      'Submitter: ${submission['submitter']}',
                                    ),
                                  if (submission['notes'].isNotEmpty)
                                    Text('Notes: ${submission['notes']}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: submission['statusColor'],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      submission['status'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Show actions only if it's the current reviewer's turn and status is actionable
                                  if (isReviewer &&
                                      ((currentReviewerName ==
                                                  submission['reviewer'] &&
                                              submission['status'] ==
                                                  'Under Review') || // Initial reviewer's turn
                                          (currentReviewerName == hodName &&
                                              submission['reviewer'] ==
                                                  hodName &&
                                              submission['status'] ==
                                                  'Forwarded to HOD'))) // HOD's turn
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        _updateDocumentStatus(
                                          submission['id'],
                                          submission['status'], // Pass current status
                                          submission['reviewer'], // Pass current assigned reviewer
                                          value, // Decision made
                                        );
                                      },
                                      itemBuilder: (BuildContext context) {
                                        if (isCurrentUserHOD &&
                                            submission['status'] ==
                                                'Forwarded to HOD') {
                                          return [
                                            PopupMenuItem(
                                              value: 'Approved',
                                              child: Text('Final Approve'),
                                            ),
                                            PopupMenuItem(
                                              value: 'Needs Revision',
                                              child: Text('Final Reject'),
                                            ),
                                          ];
                                        } else if (currentReviewerName ==
                                                submission['reviewer'] &&
                                            submission['status'] ==
                                                'Under Review') {
                                          return [
                                            PopupMenuItem(
                                              value: 'Approved',
                                              child: Text(
                                                'Approve (Forward to HOD)',
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'Needs Revision',
                                              child: Text('Reject (Final)'),
                                            ),
                                          ];
                                        }
                                        return []; // No actions if not their turn or status is final
                                      },
                                      child: Icon(Icons.more_vert),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
