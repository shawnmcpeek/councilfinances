import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

class OrganizationToggle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        final isAssemblyValue = isAssembly ?? organizationProvider.isAssembly;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isAssemblyValue) {
                      onChanged?.call(false);
                      organizationProvider.setOrganization(false);
                    }
                  },
                  style: AppTheme.getButtonStyle(isSelected: !isAssemblyValue),
                  child: const Text('Council'),
                ),
              ),
              SizedBox(width: AppTheme.spacing),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!isAssemblyValue) {
                      onChanged?.call(true);
                      organizationProvider.setOrganization(true);
                    }
                  },
                  style: AppTheme.getButtonStyle(isSelected: isAssemblyValue),
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