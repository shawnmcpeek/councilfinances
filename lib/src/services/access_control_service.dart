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
  Future<bool> needsSubscription(UserProfile userProfile) async {
    try {
      return await _subscriptionService.needsSubscription(userProfile);
    } catch (e) {
      AppLogger.error('Error checking subscription requirement', e);
      return true; // Default to requiring subscription on error
    }
  }

  // Get user's current access level for the organization
  AccessLevel getCurrentAccessLevel(UserProfile userProfile) {
    // Determine the highest access level from user's roles
    AccessLevel highestLevel = AccessLevel.basic;
    
    // Check council roles
    for (final role in userProfile.councilRoles) {
      if (role.accessLevel.index > highestLevel.index) {
        highestLevel = role.accessLevel;
      }
    }
    
    // Check assembly roles (if user has assembly access)
    if (userProfile.assemblyNumber != null) {
      for (final role in userProfile.assemblyRoles) {
        if (role.accessLevel.index > highestLevel.index) {
          highestLevel = role.accessLevel;
        }
      }
    }
    
    return highestLevel;
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

  // Check if Reimbursement screen should be visible
  Future<bool> shouldShowReimbursement(UserProfile userProfile, bool isAssembly) async {
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
  Future<List<String>> getVisibleNavigationItems(UserProfile userProfile) async {
    final List<String> visibleItems = ['home', 'finance', 'hours', 'programs', 'reimbursement'];
    
    // Add reports if user has appropriate access
    final accessLevel = getCurrentAccessLevel(userProfile);
    if (accessLevel.index >= AccessLevel.full.index) {
      visibleItems.add('reports');
    }
    
    // Add subscription if user has assembly access but needs subscription
    if (userProfile.assemblyNumber != null) {
      final needsSub = await needsSubscription(userProfile);
      if (needsSub) {
        visibleItems.add('subscription');
      }
    }
    
    return visibleItems;
  }

  // Check if user should be redirected to subscription screen
  Future<bool> shouldRedirectToSubscription(UserProfile userProfile) async {
    try {
      final currentLevel = getCurrentAccessLevel(userProfile); // Assuming isAssembly is false for this context
      
      // Basic access is always free
      if (currentLevel == AccessLevel.basic) {
        return false;
      }
      
      // Check if user needs subscription for their current level
      return await needsSubscription(userProfile);
    } catch (e) {
      AppLogger.error('Error checking subscription redirect', e);
      return false; // Default to not redirecting on error
    }
  }
} 