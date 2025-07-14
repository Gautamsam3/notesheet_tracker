import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/error_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isCheckingVerification = false;
  bool _isResendingEmail = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📧 Email verification screen initialized');
    // Don't automatically send verification email - let user trigger it manually
  }

  @override
  void dispose() {
    debugPrint('📧 Email verification screen disposed');
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isResendingEmail = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.sendEmailVerification();

      if (mounted) {
        if (success) {
          ErrorService.showSuccess(context, 'Verification email sent! Please check your inbox.');
        } else {
          ErrorService.showError(
            context, 
            userProvider.error ?? 'Failed to send verification email'
          );
        }
      }
    } catch (e) {
      debugPrint('📧❌ Error sending verification email: $e');
      if (mounted) {
        ErrorService.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    debugPrint('📧 User clicked "I\'ve Verified My Email" - checking server status');
    
    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isVerified = await userProvider.checkEmailVerification();

      if (isVerified) {
        debugPrint('✅ Email verified on server, redirecting to sign-in screen');
        if (mounted) {
          ErrorService.showSuccess(
            context, 
            'Email verified successfully! Please sign in again.'
          );
          // Small delay to let user see the success message
          await Future.delayed(const Duration(seconds: 1));
          // Redirect to sign-in screen
          Navigator.of(context).pushReplacementNamed('/signIn');
        }
      } else {
        debugPrint('❌ Email not verified on server yet');
        if (mounted) {
          ErrorService.showWarning(
            context,
            'Email not verified yet. Please check your inbox and click the verification link, then try again.',
            // Add resend action
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
      if (mounted) {
        ErrorService.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              debugPrint('🚪 User logout from verification screen');
              await userProvider.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification email to:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'your email',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Please check your inbox and click the verification link to activate your account.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCheckingVerification ? null : _checkVerification,
                icon: _isCheckingVerification
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isCheckingVerification 
                    ? 'Checking...' 
                    : 'I\'ve Verified My Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _isResendingEmail ? null : _sendVerificationEmail,
              icon: _isResendingEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.email),
              label: Text(_isResendingEmail 
                  ? 'Sending...' 
                  : 'Send Verification Email'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Tips:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Check your spam/junk folder\n'
              '• Make sure your email address is correct\n'
              '• The verification link expires after 24 hours\n'
              '• You can resend the email if needed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
