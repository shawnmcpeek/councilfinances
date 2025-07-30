import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';
import 'dart:async';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auto-create organization if it doesn't exist
  Future<void> _ensureOrganizationExists(int councilNumber, int? assemblyNumber, String jurisdiction) async {
    try {
      // Ensure council exists
      final councilId = 'C${councilNumber.toString().padLeft(6, '0')}';
      await _supabase
          .from('organizations')
          .upsert({
            'id': councilId,
            'name': 'Council #$councilNumber',
            'type': 'council',
            'jurisdiction': jurisdiction,
          })
          .eq('id', councilId);

      // Ensure assembly exists if provided
      if (assemblyNumber != null) {
        final assemblyId = 'A${assemblyNumber.toString().padLeft(6, '0')}';
        await _supabase
            .from('organizations')
            .upsert({
              'id': assemblyId,
              'name': 'Assembly #$assemblyNumber',
              'type': 'assembly',
              'jurisdiction': jurisdiction,
            })
            .eq('id', assemblyId);
      }

      AppLogger.debug('Ensured organizations exist: Council $councilId, Assembly ${assemblyNumber != null ? 'A${assemblyNumber.toString().padLeft(6, '0')}' : 'none'}');
    } catch (e) {
      AppLogger.error('Error ensuring organizations exist', e);
      // Don't rethrow - this is a best-effort operation
    }
  }

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
        'firstName': response['first_name'] ?? '',
        'lastName': response['last_name'] ?? '',
        'membershipNumber': response['membership_number'] ?? 0,
        'councilNumber': response['council_number'] ?? 0,
        'assemblyNumber': response['assembly_number'],
        'councilRoles': response['council_roles'] ?? [],
        'assemblyRoles': response['assembly_roles'] ?? [],
        'city': response['city'],
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
        'firstName': response['first_name'] ?? '',
        'lastName': response['last_name'] ?? '',
        'membershipNumber': response['membership_number'] ?? 0,
        'councilNumber': response['council_number'] ?? 0,
        'assemblyNumber': response['assembly_number'],
        'councilRoles': response['council_roles'] ?? [],
        'assemblyRoles': response['assembly_roles'] ?? [],
        'city': response['city'],
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

      // Ensure organizations exist before updating profile
      await _ensureOrganizationExists(profile.councilNumber, profile.assemblyNumber, profile.jurisdiction);

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

      return UserProfile.fromMap({
        ...response,
        'uid': response['id'],
        'firstName': response['first_name'] ?? '',
        'lastName': response['last_name'] ?? '',
        'membershipNumber': response['membership_number'] ?? 0,
        'councilNumber': response['council_number'] ?? 0,
        'assemblyNumber': response['assembly_number'],
        'councilRoles': response['council_roles'] ?? [],
        'assemblyRoles': response['assembly_roles'] ?? [],
        'city': response['city'],
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current user profile', e, stackTrace);
      return null;
    }
  }

  // Delete user profile from database
  Future<void> deleteUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      await _supabase
          .from('users')
          .delete()
          .eq('id', user.id);
    } catch (e) {
      AppLogger.error('Error deleting user profile', e);
      throw Exception('Failed to delete profile: ${e.toString()}');
    }
  }
}