import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/member_roles.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onProgramsPressed;
  
  const ProfileScreen({
    super.key,
    required this.onProgramsPressed,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _membershipNumberController = TextEditingController();
  final _councilNumberController = TextEditingController();
  final _assemblyNumberController = TextEditingController();
  bool _isLoading = true;
  List<CouncilRole> _selectedCouncilRoles = [];
  List<AssemblyRole> _selectedAssemblyRoles = [];
  bool _showCouncilRoles = false;
  bool _showAssemblyRoles = false;
  StreamSubscription<UserProfile?>? _profileSubscription;

  void _validateCouncilNumber(String value) {
    final isValid = value.isNotEmpty && 
                   int.tryParse(value) != null && 
                   value.length <= 6;
    if (_showCouncilRoles != isValid) {
      setState(() {
        _showCouncilRoles = isValid;
      });
    }
  }

  void _validateAssemblyNumber(String value) {
    final isValid = value.isNotEmpty && 
                   int.tryParse(value) != null && 
                   value.length <= 6;
    if (_showAssemblyRoles != isValid) {
      setState(() {
        _showAssemblyRoles = isValid;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    AppLogger.debug('ProfileScreen: initState called');
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    AppLogger.debug('ProfileScreen: Loading user profile');
    try {
      final profile = await _userService.getUserProfile();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _firstNameController.text = profile?.firstName ?? '';
          _lastNameController.text = profile?.lastName ?? '';
          _membershipNumberController.text = profile?.membershipNumber.toString() ?? '';
          _councilNumberController.text = profile?.councilNumber.toString() ?? '';
          _assemblyNumberController.text = profile?.assemblyNumber?.toString() ?? '';
          _selectedCouncilRoles = profile?.councilRoles ?? [];
          _selectedAssemblyRoles = profile?.assemblyRoles ?? [];
          _validateCouncilNumber(_councilNumberController.text);
          _validateAssemblyNumber(_assemblyNumberController.text);
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user profile', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    AppLogger.debug('ProfileScreen: Saving profile');
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final profile = UserProfile(
        uid: currentUser.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        membershipNumber: UserProfile.parseMembershipNumber(_membershipNumberController.text),
        councilNumber: int.parse(_councilNumberController.text),
        assemblyNumber: _assemblyNumberController.text.isEmpty
            ? null
            : int.parse(_assemblyNumberController.text),
        councilRoles: _selectedCouncilRoles,
        assemblyRoles: _selectedAssemblyRoles,
      );

      AppLogger.debug('ProfileScreen: Saving profile data: ${profile.toMap()}');
      await _userService.updateUserProfile(profile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('ProfileScreen: Error saving profile', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    AppLogger.debug('ProfileScreen: dispose called');
    _profileSubscription?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _membershipNumberController.dispose();
    _councilNumberController.dispose();
    _assemblyNumberController.dispose();
    super.dispose();
  }

  Widget _buildRoleSelector({
    required String title,
    required List<dynamic> roles,
    required List<dynamic> selectedRoles,
    required Function(List<dynamic>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.subheadingStyle),
        SizedBox(height: AppTheme.spacing),
        Wrap(
          spacing: AppTheme.smallSpacing,
          runSpacing: AppTheme.smallSpacing,
          children: roles.map((role) {
            return FilterChip(
              label: Text(role.displayName),
              selected: selectedRoles.contains(role),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    onChanged([...selectedRoles, role]);
                  } else {
                    onChanged(selectedRoles.where((r) => r != role).toList());
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: AppTheme.formFieldDecorationWithLabel('First Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: AppTheme.formFieldDecorationWithLabel('Last Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing),
              TextFormField(
                controller: _membershipNumberController,
                decoration: AppTheme.formFieldDecorationWithLabel('Membership Number'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your membership number';
                  }
                  if (value.length > 9) {
                    return 'Membership number cannot exceed 9 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppTheme.spacing),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _councilNumberController,
                        decoration: AppTheme.formFieldDecorationWithLabel('Council Number'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: _validateCouncilNumber,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your council number';
                          }
                          if (value.length > 6) {
                            return 'Council number cannot exceed 6 digits';
                          }
                          return null;
                        },
                      ),
                      if (_showCouncilRoles) ...[
                        SizedBox(height: AppTheme.spacing),
                        _buildRoleSelector(
                          title: 'Council Roles',
                          roles: CouncilRole.values,
                          selectedRoles: _selectedCouncilRoles,
                          onChanged: (roles) => setState(() => _selectedCouncilRoles = roles.cast<CouncilRole>()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacing),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _assemblyNumberController,
                        decoration: AppTheme.formFieldDecorationWithLabel('Assembly Number (optional)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: _validateAssemblyNumber,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length > 6) {
                            return 'Assembly number cannot exceed 6 digits';
                          }
                          return null;
                        },
                      ),
                      if (_showAssemblyRoles) ...[
                        SizedBox(height: AppTheme.spacing),
                        _buildRoleSelector(
                          title: 'Assembly Roles',
                          roles: AssemblyRole.values,
                          selectedRoles: _selectedAssemblyRoles,
                          onChanged: (roles) => setState(() => _selectedAssemblyRoles = roles.cast<AssemblyRole>()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.largeSpacing),
              FilledButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: AppTheme.filledButtonStyle,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Profile'),
              ),
              SizedBox(height: AppTheme.spacing),
              FilledButton(
                onPressed: widget.onProgramsPressed,
                style: AppTheme.filledButtonStyle,
                child: const Text('Define Programs'),
              ),
              SizedBox(height: AppTheme.spacing),
              OutlinedButton(
                onPressed: () async {
                  await AuthService().signOut();
                },
                style: AppTheme.outlinedButtonStyle,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 