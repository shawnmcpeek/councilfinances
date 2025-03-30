import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';
import 'dart:async';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        AppLogger.info('No profile document exists for user ${user.uid}');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        AppLogger.warning('Document exists but data is null for user ${user.uid}');
        return null;
      }

      return UserProfile.fromMap({
        ...data,
        'uid': doc.id,
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'membershipNumber': data['membershipNumber'] ?? 0,
        'councilNumber': data['councilNumber'] ?? 0,
        'councilRoles': data['councilRoles'] ?? [],
        'assemblyRoles': data['assemblyRoles'] ?? [],
      });
    } catch (e) {
      AppLogger.error('Error fetching user profile', e);
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final profileData = profile.toMap()
        ..removeWhere((key, value) => value == null);

      AppLogger.debug('Updating profile with data: $profileData');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error updating user profile', e);
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
} 