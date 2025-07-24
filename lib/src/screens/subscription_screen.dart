import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../models/member_roles.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final UserService _userService = UserService();
  
  bool _isLoading = true;
  bool _isPurchasing = false;
  UserProfile? _userProfile;
  Map<String, dynamic>? _subscriptionStatus;
  bool _needsSubscription = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() => _isLoading = true);
      
      final userProfile = await _userService.getUserProfile();
      if (!mounted) return;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final needsSubscription = await _subscriptionService.needsSubscription(userProfile);
      final subscriptionStatus = await _subscriptionService.getSubscriptionStatus();

      if (!mounted) return;
      
      setState(() {
        _userProfile = userProfile;
        _subscriptionStatus = subscriptionStatus;
        _needsSubscription = needsSubscription;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading subscription data', e);
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subscription data: ${e.toString()}')),
      );
    }
  }

  Future<void> _purchaseSingleAccess() async {
    try {
      setState(() => _isPurchasing = true);
      
      final success = await _subscriptionService.purchaseSingleAccess();
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription purchased successfully!')),
        );
        await _loadSubscriptionData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to purchase subscription')),
        );
      }
    } catch (e) {
      AppLogger.error('Error purchasing subscription', e);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error purchasing subscription: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _purchaseOrganizationAccess() async {
    try {
      setState(() => _isPurchasing = true);
      
      final success = await _subscriptionService.purchaseOrganizationAccess();
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization subscription purchased successfully!')),
        );
        await _loadSubscriptionData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to purchase organization subscription')),
        );
      }
    } catch (e) {
      AppLogger.error('Error purchasing organization subscription', e);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error purchasing subscription: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() => _isPurchasing = true);
      
      final success = await _subscriptionService.restorePurchases();
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!')),
        );
        await _loadSubscriptionData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchases found to restore')),
        );
      }
    } catch (e) {
      AppLogger.error('Error restoring purchases', e);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring purchases: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSubscriptionData,
          ),
        ],
      ),
      body: AppTheme.screenContent(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_userProfile == null) {
      return const Center(
        child: Text('User profile not found'),
      );
    }

    final isAssembly = context.watch<OrganizationProvider>().isAssembly;
    final hasActiveSubscription = _subscriptionStatus?['hasActiveSubscription'] ?? false;
    final isInTrial = _subscriptionStatus?['isInTrial'] ?? false;
    final trialEndDate = _subscriptionStatus?['trialEndDate'] as DateTime?;
    final expirationDate = _subscriptionStatus?['expirationDate'] as DateTime?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildStatusRow('Organization', isAssembly ? 'Assembly' : 'Council'),
                  _buildStatusRow('Subscription', hasActiveSubscription ? 'Active' : 'Inactive'),
                  if (isInTrial) ...[
                    _buildStatusRow('Trial Status', 'Active'),
                    if (trialEndDate != null)
                      _buildStatusRow('Trial Ends', _formatDate(trialEndDate)),
                  ],
                  if (expirationDate != null && !isInTrial)
                    _buildStatusRow('Expires', _formatDate(expirationDate)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing),
          
          // Access Level Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access Level',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildAccessLevelInfo(isAssembly),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing),
          
          // Subscription Options
          if (_needsSubscription) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Options',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    
                    // Single Access Option
                    _buildSubscriptionOption(
                      title: 'Single Access',
                      description: 'Individual subscription for full access features',
                      price: '\$1.99/year',
                      onPressed: _isPurchasing ? null : _purchaseSingleAccess,
                    ),
                    
                    const SizedBox(height: AppTheme.smallSpacing),
                    
                    // Organization Access Option
                    _buildSubscriptionOption(
                      title: 'Organization Access',
                      description: 'Group subscription for your entire organization',
                      price: '\$9.99/year',
                      onPressed: _isPurchasing ? null : _purchaseOrganizationAccess,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing),
          ],
          
          // Restore Purchases
          if (!hasActiveSubscription) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPurchasing ? null : _restorePurchases,
                icon: const Icon(Icons.restore),
                label: const Text('Restore Purchases'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _buildAccessLevelInfo(bool isAssembly) {
    if (isAssembly) {
      final roles = _userProfile!.assemblyRoles;
      AccessLevel highestLevel = AccessLevel.basic;
      
      if (roles.isNotEmpty) {
        highestLevel = roles.map((r) => r.accessLevel).reduce((a, b) => a.index > b.index ? a : b);
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow('Current Level', highestLevel.displayName),
          const SizedBox(height: 8),
          Text(
            'Roles: ${roles.map((r) => r.displayName).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    } else {
      final roles = _userProfile!.councilRoles;
      AccessLevel highestLevel = AccessLevel.basic;
      
      if (roles.isNotEmpty) {
        highestLevel = roles.map((r) => r.accessLevel).reduce((a, b) => a.index > b.index ? a : b);
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow('Current Level', highestLevel.displayName),
          const SizedBox(height: 8),
          Text(
            'Roles: ${roles.map((r) => r.displayName).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
  }

  Widget _buildSubscriptionOption({
    required String title,
    required String description,
    required String price,
    required VoidCallback? onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: _isPurchasing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
} 