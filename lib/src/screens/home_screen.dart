import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';
import '../theme/app_theme.dart';


class HomeScreen extends StatefulWidget {
  final Function(String)? onOrgChanged;

  const HomeScreen({
    super.key,
    this.onOrgChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserService();
  UserProfile? _userProfile;
  String _selectedOrg = 'council';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user profile in HomeScreen', e);
    }
  }

  String _getFormattedOrganizationId() {
    if (_userProfile == null) return '';
    
    if (_selectedOrg == 'assembly') {
      if (_userProfile?.assemblyNumber == null) return '';
      return 'A${_userProfile!.assemblyNumber.toString().padLeft(6, '0')}';
    } else {
      if (_userProfile?.councilNumber == null) return '';
      return 'C${_userProfile!.councilNumber.toString().padLeft(6, '0')}';
    }
  }

  Widget _buildOrgSelector() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: FilledButton(
              onPressed: () {
                setState(() => _selectedOrg = 'council');
                widget.onOrgChanged?.call('council');
              },
              style: FilledButton.styleFrom(
                backgroundColor: _selectedOrg == 'council' 
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withOpacity(0.1),
                foregroundColor: _selectedOrg == 'council'
                  ? Colors.white
                  : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                'Council #${_userProfile?.councilNumber ?? ""}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_userProfile?.assemblyNumber != null) ...[
            SizedBox(width: AppTheme.spacing),
            Expanded(
              flex: 1,
              child: FilledButton(
                onPressed: () {
                  setState(() => _selectedOrg = 'assembly');
                  widget.onOrgChanged?.call('assembly');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedOrg == 'assembly' 
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: _selectedOrg == 'assembly'
                    ? Colors.white
                    : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: Text(
                  'Assembly #${_userProfile?.assemblyNumber ?? ""}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Column(
        children: [
          _buildOrgSelector(),
          const Expanded(
            child: Center(
              child: Text(
                'Customize your dashboard by adding widgets',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 