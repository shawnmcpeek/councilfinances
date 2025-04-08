import 'package:flutter/material.dart';
import 'dart:async';
import '../models/program.dart';
import '../models/user_profile.dart';
import '../services/program_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../components/organization_toggle.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../components/hours_entry.dart';
import '../components/hours_history.dart';

class HoursEntryScreen extends StatefulWidget {
  const HoursEntryScreen({super.key});

  @override
  State<HoursEntryScreen> createState() => _HoursEntryScreenState();
}

class _HoursEntryScreenState extends State<HoursEntryScreen> {
  final _programService = ProgramService();
  final _userService = UserService();
  
  bool _isLoading = false;
  UserProfile? _userProfile;
  ProgramsData? _systemPrograms;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
      _loadPrograms();
    } catch (e) {
      AppLogger.error('Error loading user profile', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadPrograms() async {
    if (_userProfile == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Load system programs if we haven't yet
      _systemPrograms ??= await _programService.loadSystemPrograms();
      
      // Load program states
      await _programService.loadProgramStates(
        _systemPrograms!, 
        _userProfile!.getOrganizationId(true), 
        true
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error loading programs', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        final organizationId = _userProfile?.getOrganizationId(
          organizationProvider.isAssembly,
        ) ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hours Entry'),
          ),
          body: AppTheme.screenContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OrganizationToggle(),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (organizationId.isEmpty)
                  const Center(child: Text('Please select an organization'))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          HoursEntryForm(
                            organizationId: organizationId,
                            isAssembly: organizationProvider.isAssembly,
                          ),
                          SizedBox(height: AppTheme.spacing),
                          HoursHistoryList(
                            organizationId: organizationId,
                            isAssembly: organizationProvider.isAssembly,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 