import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/logger.dart';
import '../models/user_profile.dart';
import '../models/member_roles.dart';

class SubscriptionService {
  static const String _apiKey = 'YOUR_REVENUECAT_API_KEY'; // TODO: Replace with actual key
  
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Subscription product IDs
  static const String _singleAccessProductId = 'single_access_yearly';
  static const String _organizationAccessProductId = 'organization_access_yearly';
  
  // Entitlement IDs
  static const String _fullAccessEntitlement = 'full_access';
  static const String _readAccessEntitlement = 'read_access';

  // Initialize RevenueCat
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      AppLogger.debug('RevenueCat initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize RevenueCat', e);
      rethrow;
    }
  }

  // Get current user's subscription status
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      AppLogger.error('Error getting customer info', e);
      return null;
    }
  }

  // Check if user has active subscription for specific access level
  Future<bool> hasActiveSubscription(AccessLevel requiredLevel) async {
    try {
      final customerInfo = await getCustomerInfo();
      if (customerInfo == null) return false;

      // Check entitlements based on required access level
      switch (requiredLevel) {
        case AccessLevel.basic:
          return true; // Everyone has basic access
        case AccessLevel.read:
          return customerInfo.entitlements.active.containsKey(_readAccessEntitlement) ||
                 customerInfo.entitlements.active.containsKey(_fullAccessEntitlement);
        case AccessLevel.full:
          return customerInfo.entitlements.active.containsKey(_fullAccessEntitlement);
      }
    } catch (e) {
      AppLogger.error('Error checking subscription status', e);
      return false;
    }
  }

  // Check if user is in trial period
  Future<bool> isInTrialPeriod() async {
    try {
      final customerInfo = await getCustomerInfo();
      if (customerInfo == null) return false;

      // Check if any active entitlement is in trial
      return customerInfo.entitlements.active.values.any((entitlement) => 
        entitlement.periodType == PeriodType.trial);
    } catch (e) {
      AppLogger.error('Error checking trial status', e);
      return false;
    }
  }

  // Get trial end date
  Future<DateTime?> getTrialEndDate() async {
    try {
      final customerInfo = await getCustomerInfo();
      if (customerInfo == null) return null;

      // Find the earliest trial end date among active entitlements
      DateTime? earliestTrialEnd;
      for (final entitlement in customerInfo.entitlements.active.values) {
        if (entitlement.periodType == PeriodType.trial) {
          final trialEndString = entitlement.expirationDate;
          if (trialEndString != null) {
            final trialEnd = DateTime.tryParse(trialEndString);
            if (trialEnd != null && (earliestTrialEnd == null || trialEnd.isBefore(earliestTrialEnd))) {
              earliestTrialEnd = trialEnd;
            }
          }
        }
      }
      return earliestTrialEnd;
    } catch (e) {
      AppLogger.error('Error getting trial end date', e);
      return null;
    }
  }

  // Purchase single access subscription
  Future<bool> purchaseSingleAccess() async {
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      
      if (currentOffering == null) {
        AppLogger.error('No current offering available');
        return false;
      }

      final package = currentOffering.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == _singleAccessProductId,
        orElse: () => throw Exception('Single access package not found'),
      );

      final customerInfo = await Purchases.purchasePackage(package);
      AppLogger.debug('Single access subscription purchased successfully');
      return customerInfo.entitlements.active.containsKey(_fullAccessEntitlement);
    } catch (e) {
      AppLogger.error('Error purchasing single access subscription', e);
      return false;
    }
  }

  // Purchase organization access subscription
  Future<bool> purchaseOrganizationAccess() async {
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      
      if (currentOffering == null) {
        AppLogger.error('No current offering available');
        return false;
      }

      final package = currentOffering.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == _organizationAccessProductId,
        orElse: () => throw Exception('Organization access package not found'),
      );

      final customerInfo = await Purchases.purchasePackage(package);
      AppLogger.debug('Organization access subscription purchased successfully');
      return customerInfo.entitlements.active.containsKey(_fullAccessEntitlement);
    } catch (e) {
      AppLogger.error('Error purchasing organization access subscription', e);
      return false;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      AppLogger.debug('Purchases restored successfully');
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error restoring purchases', e);
      return false;
    }
  }

  // Get subscription offerings
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      AppLogger.error('Error getting offerings', e);
      return null;
    }
  }

  // Check if user needs subscription for their access level
  Future<bool> needsSubscription(UserProfile userProfile, bool isAssembly) async {
    try {
      // Determine user's highest access level
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

      // Basic access is always free
      if (highestLevel == AccessLevel.basic) {
        return false;
      }

      // Check if user has active subscription for their level
      return !await hasActiveSubscription(highestLevel);
    } catch (e) {
      AppLogger.error('Error checking if user needs subscription', e);
      return true; // Default to requiring subscription on error
    }
  }

  // Get subscription status for display
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final customerInfo = await getCustomerInfo();
      final isInTrial = await isInTrialPeriod();
      final trialEndDate = await getTrialEndDate();

      return {
        'hasActiveSubscription': customerInfo?.entitlements.active.isNotEmpty ?? false,
        'isInTrial': isInTrial,
        'trialEndDate': trialEndDate,
        'activeEntitlements': customerInfo?.entitlements.active.keys.toList() ?? [],
        'expirationDate': customerInfo?.entitlements.active.values
            .map((e) => e.expirationDate)
            .where((date) => date != null)
            .map((date) => DateTime.tryParse(date!))
            .where((date) => date != null)
            .reduce((a, b) => a!.isAfter(b!) ? a : b),
      };
    } catch (e) {
      AppLogger.error('Error getting subscription status', e);
      return {
        'hasActiveSubscription': false,
        'isInTrial': false,
        'trialEndDate': null,
        'activeEntitlements': [],
        'expirationDate': null,
      };
    }
  }
} 