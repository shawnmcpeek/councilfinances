import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../components/organization_toggle.dart';
import '../components/program_budget.dart';
import '../components/period_report_selector.dart';
import '../reports/form1728_report.dart';
import '../reports/volunteer_hours_report.dart';
import '../providers/organization_provider.dart';
import '../reports/period_report_service.dart';
import '../models/member_roles.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _userService = UserService();
  String selectedYear = DateTime.now().year.toString();
  bool isGeneratingForm1728 = false;
  bool isGeneratingVolunteerHours = false;
  bool _isLoading = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _userService.getUserProfile();
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: ${e.toString()}')),
        );
      }
    }
  }

  bool _hasFinancialAccess() {
    return (_userProfile?.councilRoles.any((role) => role.accessLevel == AccessLevel.full) ?? false) ||
           (_userProfile?.assemblyRoles.any((role) => role.accessLevel == AccessLevel.full) ?? false);
  }

  bool _hasProgramAccess() {
    return (_userProfile?.councilRoles.any((role) => role.accessLevel == AccessLevel.read || role.accessLevel == AccessLevel.full) ?? false) ||
           (_userProfile?.assemblyRoles.any((role) => role.accessLevel == AccessLevel.read || role.accessLevel == AccessLevel.full) ?? false);
  }

  bool _hasVolunteerAccess() {
    return (_userProfile?.councilRoles.isNotEmpty ?? false) ||
           (_userProfile?.assemblyRoles.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view reports')),
      );
    }

    final organizationProvider = context.watch<OrganizationProvider>();
    final organizationId = _userProfile?.getOrganizationId(
      organizationProvider.isAssembly,
    ) ?? '';

    if (organizationId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please select an organization')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: AppTheme.screenContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OrganizationToggle(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasFinancialAccess()) ...[
                      const PeriodReportSelector(),
                      const SizedBox(height: 24),
                      const Divider(),
                    ],
                    if (_hasProgramAccess()) ...[
                      Form1728Report(
                        organizationId: organizationId,
                        selectedYear: selectedYear,
                        isGenerating: isGeneratingForm1728,
                        onGeneratingChange: (value) => setState(() => isGeneratingForm1728 = value),
                        onYearChange: (value) => setState(() => selectedYear = value),
                      ),
                      SizedBox(height: AppTheme.spacing),
                      if (organizationId.isNotEmpty)
                        ProgramBudget(
                          organizationId: organizationId,
                        ),
                      const SizedBox(height: 24),
                      const Divider(),
                    ],
                    if (_hasVolunteerAccess()) ...[
                      VolunteerHoursReport(
                        userId: _userProfile!.uid,
                        organizationId: organizationId,
                        selectedYear: selectedYear,
                        isGenerating: isGeneratingVolunteerHours,
                        onGeneratingChange: (value) => setState(() => isGeneratingVolunteerHours = value),
                        onYearChange: (value) => setState(() => selectedYear = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}