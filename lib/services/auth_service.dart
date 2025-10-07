import 'package:firebase_auth/firebase_auth.dart';

/// This service handles all Firebase Authentication operations
/// Think of it as your authentication "helper" that talks to Firebase
class AuthService {
  // Get the Firebase Auth instance (singleton pattern - only one instance exists)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user
  // Returns null if no one is logged in
  User? get currentUser => _auth.currentUser;

  // Stream of authentication state changes
  // This is like a "live feed" that notifies you whenever the user logs in or out
  // Your app can "listen" to this stream and react automatically
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  /// Returns the User if successful, or throws an exception if something goes wrong
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Create the user account in Firebase
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If a display name was provided, update the user's profile
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload(); // Refresh to get updated info
        return _auth.currentUser; // Return the updated user
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors with user-friendly messages
      throw _handleAuthException(e);
    } catch (e) {
      // Handle any other unexpected errors
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign in with email and password
  /// Returns the User if successful, or throws an exception if credentials are wrong
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Send password reset email
  /// The user will receive an email with a link to reset their password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send reset email. Please try again.';
    }
  }

  /// Send email verification to the current user
  /// Users should verify their email after signing up
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email. Please try again.';
    }
  }

  /// Reload current user data
  /// Useful after updating profile information
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Check if the current user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Delete the current user account
  /// WARNING: This is permanent and cannot be undone!
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  /// Update user password
  /// The user must have signed in recently for this to work
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update password. Please try again.';
    }
  }

  /// Re-authenticate user (needed for sensitive operations like deleting account)
  /// This is like asking the user to confirm their password before doing something important
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'No user is currently signed in.';
      }

      // Create credential with current email and provided password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to re-authenticate. Please try again.';
    }
  }

  /// Convert Firebase Auth exceptions to user-friendly error messages
  /// This makes error messages easier to understand for users
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to perform this action.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}