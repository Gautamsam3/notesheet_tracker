import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current Supabase user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String department,
  }) async {
    debugPrint('🔐 SupabaseAuthService: Creating account for $email');
    
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'department': department,
        },
      );

      if (response.user != null) {
        debugPrint('✅ SupabaseAuthService: Account created successfully for $email');
        debugPrint('📧 SupabaseAuthService: Please check your email to confirm your account');
        
        // Create user profile in Supabase
        await _createUserProfile(
          uid: response.user!.id,
          name: name,
          email: email,
          department: department,
          role: 'requester', // Default role for new signups
        );
      }

      return response;
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Sign up failed for $email: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<AuthResponse?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 SupabaseAuthService: Sign in attempt for $email');
    
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ SupabaseAuthService: Sign in successful for $email');
      }

      return response;
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Sign in failed for $email: $e');
      throw Exception(_handleSupabaseAuthException(e.toString()));
    }
  }

  // Sign out
  Future<void> signOut() async {
    debugPrint('🔐 SupabaseAuthService: Signing out');
    
    try {
      await _supabase.auth.signOut();
      debugPrint('✅ SupabaseAuthService: Sign out successful');
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && user.emailConfirmedAt == null) {
      try {
        debugPrint('📧 SupabaseAuthService: Sending email verification to ${user.email}');
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: user.email!,
        );
        debugPrint('✅ SupabaseAuthService: Email verification sent');
      } catch (e) {
        debugPrint('❌ SupabaseAuthService: Failed to send email verification: $e');
        throw Exception('Failed to send email verification: $e');
      }
    }
  }

  // Check email verification status by refreshing user data from server
  Future<bool> isEmailVerified() async {
    try {
      debugPrint('📧 SupabaseAuthService: Checking email verification status from server');
      
      // Refresh the user session to get latest data from server
      await _supabase.auth.refreshSession();
      
      final user = currentUser;
      final isVerified = user?.emailConfirmedAt != null;
      
      debugPrint('📧 SupabaseAuthService: Email verification status: $isVerified');
      debugPrint('📧 SupabaseAuthService: Email confirmed at: ${user?.emailConfirmedAt}');
      
      return isVerified;
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to check email verification: $e');
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('🔐 SupabaseAuthService: Sending password reset email to $email');
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('✅ SupabaseAuthService: Password reset email sent');
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to send password reset email: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Public method to create user profile (for profile completion)
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String department,
    String role = 'requester',
  }) async {
    await _createUserProfile(
      uid: uid,
      name: name,
      email: email,
      department: department,
      role: role,
    );
  }

  // Helper method to convert string role to UserRole enum
  UserRole? _getUserRoleFromString(String? roleString) {
    if (roleString == null) return null;
    
    switch (roleString.toLowerCase()) {
      case 'requester':
        return UserRole.requester;
      case 'reviewer':
        return UserRole.reviewer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.requester; // Default to requester
    }
  }

  // Create user profile in Supabase
  Future<void> _createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String department,
    String role = 'requester',
  }) async {
    try {
      debugPrint('📄 SupabaseAuthService: Creating user profile for $uid');
      
      // Try using the simple SQL function first (most reliable with RLS)
      try {
        final result = await _supabase.rpc('create_user_profile_simple', params: {
          'user_uid': uid,
          'user_name': name,
          'user_email': email,
          'user_department': department,
          'user_role': role,
        });
        
        if (result['success'] == true) {
          debugPrint('✅ SupabaseAuthService: User profile created using simple SQL function');
          return;
        } else {
          debugPrint('⚠️ SupabaseAuthService: Simple SQL function failed: ${result['error']}');
        }
      } catch (rpcError) {
        debugPrint('⚠️ SupabaseAuthService: Simple SQL function failed, trying legacy function: $rpcError');
        
        // Try the legacy function
        try {
          await _supabase.rpc('create_user_profile', params: {
            'user_uid': uid,
            'user_name': name,
            'user_email': email,
            'user_department': department,
            'user_role': role,
          });
          debugPrint('✅ SupabaseAuthService: User profile created using legacy SQL function');
          return;
        } catch (legacyError) {
          debugPrint('⚠️ SupabaseAuthService: Legacy SQL function also failed, trying direct insert: $legacyError');
        }
      }
      
      // Fallback to direct insert
      AppUser userModel = AppUser(
        uid: uid,
        name: name,
        email: email,
        department: department,
        role: _getUserRoleFromString(role),
        createdAt: DateTime.now(),
      );

      await _supabase.from('users').insert(userModel.toJson());
      debugPrint('✅ SupabaseAuthService: User profile created using direct insert');
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to create user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Ensure user profile exists for Google users
  Future<void> _ensureUserProfile(User user) async {
    try {
      // Check if profile already exists
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', user.id)
          .maybeSingle();

      if (response == null) {
        // Create profile for new Google user
        await _createUserProfile(
          uid: user.id,
          name: user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Google User',
          email: user.email!,
          department: 'Not specified',
          role: 'requester', // Default role for Google users
        );
        debugPrint('✅ SupabaseAuthService: Google user profile created');
      }
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to ensure user profile: $e');
    }
  }

  // Get user profile
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to get user profile: $e');
      return null;
    }
  }

  // Get all users (for reviewer selection)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select();
      
      return response
          .map((data) => AppUser.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to get all users: $e');
      throw Exception('Failed to get users: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? department,
  }) async {
    try {
      debugPrint('📄 SupabaseAuthService: Updating user profile for $uid');
      
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (department != null) updates['department'] = department;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').update(updates).eq('uid', uid);
      debugPrint('✅ SupabaseAuthService: User profile updated successfully');
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Failed to update user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  String _handleSupabaseAuthException(String error) {
    if (error.contains('email_not_confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    } else if (error.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (error.contains('email_address_invalid')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('password_too_short')) {
      return 'Password must be at least 6 characters long.';
    } else if (error.contains('signup_disabled')) {
      return 'New user registration is currently disabled.';
    } else if (error.contains('email_address_not_authorized')) {
      return 'This email address is not authorized to create an account.';
    } else if (error.contains('user_already_registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    } else if (error.contains('captcha_failed')) {
      return 'Captcha verification failed. Please try again.';
    } else if (error.contains('over_email_send_rate_limit')) {
      return 'Too many emails sent. Please wait before requesting another.';
    } else if (error.contains('over_request_rate_limit')) {
      return 'Too many requests. Please wait a moment before trying again.';
    }
    
    return 'Authentication error: $error';
  }

  // Get current authentication status
  String getAuthStatus() {
    final user = currentUser;
    
    if (user == null) {
      return 'Not authenticated';
    } else if (user.emailConfirmedAt == null) {
      return 'Email not verified';
    } else {
      return 'Fully authenticated';
    }
  }

  // Check if user can upload files
  bool canUploadFiles() {
    final user = currentUser;
    return user != null && user.emailConfirmedAt != null;
  }

  // Get user-friendly error message for file operations
  String getFileUploadErrorMessage() {
    final user = currentUser;
    
    if (user == null) {
      return 'Please sign in to upload files.';
    }
    
    if (user.emailConfirmedAt == null) {
      return 'Please verify your email address before uploading files.';
    }
    
    return 'Ready to upload files.';
  }
}
