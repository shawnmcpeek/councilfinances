import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Development-only auto-login credentials
  static const _devEmail = 'shawn.mcpeek@gmail.com';
  static const _devPassword = 'Mgti18il';

  Future<User?> autoLoginForDevelopment() async {
    if (!kDebugMode) {
      AppLogger.warning('Auto-login is only available in debug mode');
      return null;
    }

    try {
      // Sign in with the development credentials
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _devEmail,
        password: _devPassword,
      );
      
      return userCredential.user;
    } catch (e) {
      AppLogger.error('Auto-login failed', e);
      return null;
    }
  }

  // Regular authentication methods
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      AppLogger.error('Sign in failed', e);
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 