import '../models/user_profile.dart';
import '../models/member_roles.dart';
import '../services/subscription_service.dart';
import '../utils/logger.dart';

class AccessControlService {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  // Singleton pattern
  static final AccessControlService _instance = AccessControlService._internal();
  factory AccessControlService() => _instance;
  AccessControlService._internal();

  // Check if user has access to a specific feature
  Future<bool> hasAccess(UserProfile userProfile, bool isAssembly, AccessLevel requiredLevel) async {
    try {
      // Determine user's highest access level for the current organization
      AccessLevel userLevel = AccessLevel.basic;
      
      if (isAssembly) {
        for (final role in userProfile.assemblyRoles) {
          if (role.accessLevel.index > userLevel.index) {
            userLevel = role.accessLevel;
          }
        }
      } else {
        for (final role in userProfile.councilRoles) {
          if (role.accessLevel.index > userLevel.index) {
            userLevel = role.accessLevel;
          }
        }
      }

      // Basic access is always available
      if (requiredLevel == AccessLevel.basic) {
        return true;
      }

      // Check if user's role level meets the requirement
      if (userLevel.index < requiredLevel.index) {
        return false;
      }

      // For read and full access, check subscription status
      if (requiredLevel == AccessLevel.read || requiredLevel == AccessLevel.full) {
        return await _subscriptionService.hasActiveSubscription(requiredLevel);
      }

      return true;
    } catch (e) {
      AppLogger.error('Error checking access permissions', e);
      return false; // Default to denying access on error
    }
  }

  // Check if user needs subscription for their current access level
  Future<bool> needsSubscription(UserProfile userProfile, bool isAssembly) async {
    try {
      return await _subscriptionService.needsSubscription(userProfile, isAssembly);
    } catch (e) {
      AppLogger.error('Error checking subscription requirement', e);
      return true; // Default to requiring subscription on error
    }
  }

  // Get user's current access level for the organization
  AccessLevel getCurrentAccessLevel(UserProfile userProfile, bool isAssembly) {
    try {
      AccessLevel highestLevel = AccessLevel.basic;
      
      if (isAssembly) {
        for (final role in userProfile.assemblyRoles) {
          if (role.accessLevel.index > highestLevel.index) {
            highestLevel = role.accessLevel;
          }
        }
      } else {
        for (final role in userProfile.councilRoles) {
          if (role.accessLevel.index > highestLevel.index) {
            highestLevel = role.accessLevel;
          }
        }
      }
      
      return highestLevel;
    } catch (e) {
      AppLogger.error('Error getting current access level', e);
      return AccessLevel.basic; // Default to basic access on error
    }
  }

  // Check if Finance screen should be visible
  Future<bool> shouldShowFinance(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.full);
  }

  // Check if Reports screen should be visible
  Future<bool> shouldShowReports(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.read);
  }

  // Check if Programs screen should be visible
  Future<bool> shouldShowPrograms(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.basic);
  }

  // Check if Hours screen should be visible
  Future<bool> shouldShowHours(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.basic);
  }

  // Check if user can edit programs (Define Programs)
  Future<bool> canEditPrograms(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.full);
  }

  // Check if user can edit financial entries
  Future<bool> canEditFinance(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.full);
  }

  // Check if user can delete their own entries
  Future<bool> canDeleteOwnEntries(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.basic);
  }

  // Check if user can view all entries (not just their own)
  Future<bool> canViewAllEntries(UserProfile userProfile, bool isAssembly) async {
    return await hasAccess(userProfile, isAssembly, AccessLevel.read);
  }

  // Get list of visible navigation items
  Future<List<String>> getVisibleNavigationItems(UserProfile userProfile, bool isAssembly) async {
    final items = <String>[];
    
    // Home is always visible
    items.add('home');
    
    // Check other screens
    if (await shouldShowPrograms(userProfile, isAssembly)) {
      items.add('programs');
    }
    
    if (await shouldShowHours(userProfile, isAssembly)) {
      items.add('hours');
    }
    
    if (await shouldShowFinance(userProfile, isAssembly)) {
      items.add('finance');
    }
    
    if (await shouldShowReports(userProfile, isAssembly)) {
      items.add('reports');
    }
    
    // Profile is always visible
    items.add('profile');
    
    return items;
  }

  // Check if user should be redirected to subscription screen
  Future<bool> shouldRedirectToSubscription(UserProfile userProfile, bool isAssembly) async {
    try {
      final currentLevel = getCurrentAccessLevel(userProfile, isAssembly);
      
      // Basic access is always free
      if (currentLevel == AccessLevel.basic) {
        return false;
      }
      
      // Check if user needs subscription for their current level
      return await needsSubscription(userProfile, isAssembly);
    } catch (e) {
      AppLogger.error('Error checking subscription redirect', e);
      return false; // Default to not redirecting on error
    }
  }
} 