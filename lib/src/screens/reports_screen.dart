import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../components/organization_toggle.dart';
import '../components/program_budget.dart';
import '../reports/form1728_report.dart';
import '../reports/volunteer_hours_report.dart';
import '../providers/organization_provider.dart';

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
                  children: [
                    Form1728Report(
                      organizationId: organizationId,
                      selectedYear: selectedYear,
                      isGenerating: isGeneratingForm1728,
                      onGeneratingChange: (value) => setState(() => isGeneratingForm1728 = value),
                      onYearChange: (value) => setState(() => selectedYear = value),
                    ),
                    SizedBox(height: AppTheme.spacing),
                    VolunteerHoursReport(
                      userId: _userProfile!.uid,
                      organizationId: organizationId,
                      selectedYear: selectedYear,
                      isGenerating: isGeneratingVolunteerHours,
                      onGeneratingChange: (value) => setState(() => isGeneratingVolunteerHours = value),
                      onYearChange: (value) => setState(() => selectedYear = value),
                    ),
                    SizedBox(height: AppTheme.spacing),
                    if (organizationId.isNotEmpty)
                      ProgramBudget(
                        organizationId: organizationId,
                      ),
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