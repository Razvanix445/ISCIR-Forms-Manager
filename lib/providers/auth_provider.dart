import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// This provider manages authentication state for the entire app
/// It uses ChangeNotifier so widgets can listen to authentication changes
class MyAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  MyAuthProvider() {

    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      _user = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Sign in an existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _user = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _user = null;
      _errorMessage = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      await _authService.sendEmailVerification();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Get current user's display name or email
  String get userDisplayName {
    if (_user == null) return 'Guest';
    return _user!.displayName ?? _user!.email ?? 'User';
  }

  /// Check if email is verified
  bool get isEmailVerified => _authService.isEmailVerified;
}