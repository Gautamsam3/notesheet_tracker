import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';

class UserProvider with ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  SupabaseAuthService get authService => _authService;

  UserProvider() {
    debugPrint('👤 UserProvider initialized');
    _initializeAuth();
  }

  void _initializeAuth() {
    debugPrint('🔄 Initializing Supabase authentication listener');
    _authService.authStateChanges.listen((AuthState authState) {
      final user = authState.session?.user;
      debugPrint('🔄 Auth state changed: ${user?.id ?? 'null'}');
      
      if (user != null) {
        debugPrint('✅ Supabase user found, loading profile: ${user.id}');
        _loadUserProfile(user.id);
      } else {
        debugPrint('❌ No Supabase user, clearing current user');
        _currentUser = null;
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    debugPrint('📄 Loading user profile for UID: $uid');
    
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.getUserProfile(uid);
      if (user != null) {
        _currentUser = user;
        debugPrint('✅ User profile loaded successfully: ${user.name} (${user.email})');
        debugPrint('🔑 User role: ${user.role?.name ?? 'null'}');
        debugPrint('📊 User permissions: requester=${user.isRequester}, reviewer=${user.isReviewer}, admin=${user.isAdmin}');
        
        // Check authentication status
        debugPrint('🔄 Checking authentication status...');
        final authStatus = _authService.getAuthStatus();
        debugPrint('✅ Authentication status: $authStatus');
        
        if (!_authService.canUploadFiles()) {
          debugPrint('⚠️ Email not verified - file uploads disabled');
        } else {
          debugPrint('✅ Ready for file uploads');
        }
      } else {
        debugPrint('⚠️ User profile not found for UID: $uid');
        _setError('User profile not found');
      }
    } catch (e) {
      debugPrint('❌ Failed to load user profile for UID: $uid - $e');
      _setError('Failed to load user profile: $e');
    } finally {
      _setLoading(false);
      notifyListeners(); // Ensure listeners are notified
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String department,
  }) async {
    debugPrint('📝 Sign up attempt for email: $email');
    
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        department: department,
      );

      if (userCredential != null) {
        debugPrint('✅ Sign up successful for email: $email');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Sign up failed for email: $email - $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 Sign in attempt for email: $email');
    
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        debugPrint('✅ Sign in successful for email: $email');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Sign in failed for email: $email - $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    debugPrint('🚪 Sign out attempt for user: ${_currentUser?.email ?? 'unknown'}');
    
    try {
      await _authService.signOut();
      // Clear current user state immediately
      _currentUser = null;
      _clearError();
      notifyListeners();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      _setError('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    debugPrint('🔄 Password reset attempt for email: $email');
    
    try {
      _clearError();
      await _authService.resetPassword(email);
      debugPrint('✅ Password reset email sent to: $email');
      return true;
    } catch (e) {
      debugPrint('❌ Password reset failed for email: $email - $e');
      _setError(e.toString());
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    debugPrint('📧 Sending email verification');
    
    try {
      await _authService.sendEmailVerification();
      debugPrint('✅ Email verification sent');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to send email verification: $e');
      _setError(e.toString());
      return false;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      debugPrint('📧 UserProvider: Checking email verification status');
      final isVerified = await _authService.isEmailVerified();
      debugPrint('📧 UserProvider: Email verification status: $isVerified');
      return isVerified;
    } catch (e) {
      debugPrint('❌ UserProvider: Failed to check email verification: $e');
      return false;
    }
  }

  // Get all users for reviewer selection
  Future<List<AppUser>> getAllUsers() async {
    debugPrint('👥 Fetching all users');
    
    try {
      final users = await _authService.getAllUsers();
      debugPrint('✅ Fetched ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('❌ Failed to fetch users: $e');
      _setError('Failed to fetch users: $e');
      return [];
    }
  }

  // Refresh user profile
  Future<void> refreshUserProfile() async {
    debugPrint('🔄 Manually refreshing user profile');
    
    final supabaseUser = _authService.currentUser;
    if (supabaseUser != null) {
      await _loadUserProfile(supabaseUser.id);
    } else {
      debugPrint('❌ No Supabase user to refresh profile for');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    debugPrint('👤 UserProvider disposed');
    super.dispose();
  }
}
