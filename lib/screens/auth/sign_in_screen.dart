import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/error_service.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔐 SignInScreen initialized');
  }

  @override
  void dispose() {
    debugPrint('🔐 SignInScreen disposed');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSigningIn) {
      debugPrint('🔐⚠️ Sign in already in progress, ignoring duplicate request');
      return;
    }
    
    debugPrint('🔐 Sign in attempt for: ${_emailController.text.trim()}');
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSigningIn = true;
      });
      
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        final success = await userProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (success) {
          debugPrint('🔐✅ Sign in successful for: ${_emailController.text.trim()}');
          // Navigation will be handled by AuthWrapper
        } else {
          debugPrint('🔐❌ Sign in failed for: ${_emailController.text.trim()}: ${userProvider.error}');
          
          if (mounted) {
            ErrorService.showError(context, userProvider.error ?? 'Sign in failed');
          }
        }
      } catch (e) {
        debugPrint('🔐❌ Unexpected error during sign in: $e');
        if (mounted) {
          ErrorService.showError(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
      }
    } else {
      debugPrint('🔐❌ Sign in form validation failed');
    }
  }

  Future<void> _resetPassword() async {
    debugPrint('🔐 Password reset attempt for: ${_emailController.text.trim()}');
    
    if (_emailController.text.trim().isEmpty) {
      debugPrint('🔐❌ Password reset attempted with empty email');
      
      ErrorService.showWarning(context, 'Please enter your email address');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.resetPassword(_emailController.text.trim());

    if (success) {
      debugPrint('🔐✅ Password reset email sent to: ${_emailController.text.trim()}');
      if (mounted) {
        ErrorService.showSuccess(context, 'Password reset email sent');
      }
    } else {
      debugPrint('🔐❌ Password reset failed for: ${_emailController.text.trim()}: ${userProvider.error}');
      if (mounted) {
        ErrorService.showError(context, userProvider.error ?? 'Failed to send reset email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title
                Icon(
                  Icons.description,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Notesheet Tracker',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign in button
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return ElevatedButton(
                      onPressed: userProvider.isLoading ? null : _signIn,
                      child: userProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
