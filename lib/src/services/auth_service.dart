import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      AppLogger.error('Error signing in with email and password', e);
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      AppLogger.error('Error signing up with email and password', e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.error('Error signing out', e);
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
}
