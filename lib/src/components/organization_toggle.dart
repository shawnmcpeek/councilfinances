import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class OrganizationToggle extends StatefulWidget {
  final UserProfile? userProfile;
  final bool? isAssembly;
  final Function(bool)? onChanged;

  const OrganizationToggle({
    super.key,
    this.userProfile,
    this.isAssembly,
    this.onChanged,
  });

  @override
  State<OrganizationToggle> createState() => _OrganizationToggleState();
}

class _OrganizationToggleState extends State<OrganizationToggle> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userService = UserService();
      final profile = await userService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppTheme.smallSpacing),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        final isAssemblyValue = widget.isAssembly ?? organizationProvider.isAssembly;
        final hasAssemblyData = _userProfile?.assemblyNumber != null && 
                               _userProfile?.assemblyRoles.isNotEmpty == true;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
          child: Row(
            children: [
              Expanded(
                child: !isAssemblyValue 
                  ? FilledButton(
                      onPressed: () {
                        if (isAssemblyValue) {
                          widget.onChanged?.call(false);
                          organizationProvider.setOrganization(false);
                        }
                      },
                      style: AppTheme.filledButtonStyle,
                      child: const Text('Council'),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        if (isAssemblyValue) {
                          widget.onChanged?.call(false);
                          organizationProvider.setOrganization(false);
                        }
                      },
                      style: AppTheme.outlinedButtonStyle,
                      child: const Text('Council'),
                    ),
              ),
              SizedBox(width: AppTheme.spacing),
              Expanded(
                child: isAssemblyValue 
                  ? FilledButton(
                      onPressed: hasAssemblyData ? () {
                        if (!isAssemblyValue) {
                          widget.onChanged?.call(true);
                          organizationProvider.setOrganization(true);
                        }
                      } : null,
                      style: hasAssemblyData 
                        ? AppTheme.filledButtonStyle
                        : AppTheme.filledButtonStyle.copyWith(
                            backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                            foregroundColor: WidgetStateProperty.all(Colors.grey[600]),
                          ),
                      child: const Text('Assembly'),
                    )
                  : OutlinedButton(
                      onPressed: hasAssemblyData ? () {
                        if (!isAssemblyValue) {
                          widget.onChanged?.call(true);
                          organizationProvider.setOrganization(true);
                        }
                      } : null,
                      style: hasAssemblyData 
                        ? AppTheme.outlinedButtonStyle
                        : AppTheme.outlinedButtonStyle.copyWith(
                            backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                            foregroundColor: WidgetStateProperty.all(Colors.grey[600]),
                          ),
                      child: const Text('Assembly'),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
} 