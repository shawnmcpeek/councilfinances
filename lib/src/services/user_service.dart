import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';
import 'dart:async';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap({
        ...response,
        'uid': response['id'],
        'firstName': response['firstName'] ?? '',
        'lastName': response['lastName'] ?? '',
        'membershipNumber': response['membershipNumber'] ?? 0,
        'councilNumber': response['councilNumber'] ?? 0,
        'councilRoles': response['councilRoles'] ?? [],
        'assemblyRoles': response['assemblyRoles'] ?? [],
      });
    } catch (e) {
      AppLogger.error('Error fetching user profile', e);
      return null;
    }
  }

  // Get user profile by ID
  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      AppLogger.info('Fetching user profile for ID: $userId');
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromMap({
        ...response,
        'uid': response['id'],
        'firstName': response['firstName'] ?? '',
        'lastName': response['lastName'] ?? '',
        'membershipNumber': response['membershipNumber'] ?? 0,
        'councilNumber': response['councilNumber'] ?? 0,
        'councilRoles': response['councilRoles'] ?? [],
        'assemblyRoles': response['assemblyRoles'] ?? [],
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching user profile by ID', e, stackTrace);
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final profileData = profile.toMap()
        ..removeWhere((key, value) => value == null);

      AppLogger.debug('Updating profile with data: $profileData');

      await _supabase
          .from('users')
          .upsert(profileData)
          .eq('id', user.id);
    } catch (e) {
      AppLogger.error('Error updating user profile', e);
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current user profile', e, stackTrace);
      return null;
    }
  }
}