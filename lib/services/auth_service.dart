import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Register a new user
  Future<SignUpResult> register(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      // If Supabase returns user OR session, signup succeeded
      if (response.user != null || response.session != null) {
        final requiresConfirmation = response.session == null;

        return SignUpResult(
          success: true,
          requiresEmailConfirmation: requiresConfirmation,
          message: requiresConfirmation
              ? 'Account created. Please verify your email.'
              : null,
        );
      }

      return SignUpResult(
        success: false,
        requiresEmailConfirmation: false,
        message: 'Registration failed. Please try again.',
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      // Supabase retry edge case: user actually already created
      if (msg.contains('already') ||
          msg.contains('exists') ||
          msg.contains('registered') ||
          _supabase.auth.currentUser != null) {
        return SignUpResult(
          success: true,
          requiresEmailConfirmation: true,
          message: 'Account created. Please verify your email.',
        );
      }

      return SignUpResult(
        success: false,
        requiresEmailConfirmation: false,
        message: e.message,
      );
    } catch (_) {
      return SignUpResult(
        success: false,
        requiresEmailConfirmation: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Login user
  Future<User> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return response.user!;
      }

      throw AuthException('Login failed. Please try again.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // Get current logged-in user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Logout user
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Get Supabase client (for other services)
  SupabaseClient get supabase => _supabase;
}

// Result class for sign up operation
class SignUpResult {
  final bool success;
  final bool requiresEmailConfirmation;
  final String? message;

  SignUpResult({
    required this.success,
    required this.requiresEmailConfirmation,
    this.message,
  });
}
