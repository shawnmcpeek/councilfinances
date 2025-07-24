import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  final UserService _userService = UserService();

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoaded => _userProfile != null;

  /// Load user profile once and cache it
  Future<void> loadUserProfile() async {
    if (_userProfile != null) {
      // Already loaded, no need to reload
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _error = null;
        _isLoading = false;
      });
      AppLogger.debug('User profile loaded successfully');
    } catch (e) {
      AppLogger.error('Error loading user profile', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get organization ID for the specified type
  String? getOrganizationId(bool isAssembly) {
    return _userProfile?.getOrganizationId(isAssembly);
  }

  /// Refresh user profile (useful after profile updates)
  Future<void> refreshUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _error = null;
        _isLoading = false;
      });
      AppLogger.debug('User profile refreshed successfully');
    } catch (e) {
      AppLogger.error('Error refreshing user profile', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Clear user profile (useful on logout)
  void clearUserProfile() {
    setState(() {
      _userProfile = null;
      _error = null;
      _isLoading = false;
    });
    AppLogger.debug('User profile cleared');
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 