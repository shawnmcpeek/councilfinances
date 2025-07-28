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
import '../models/member_roles.dart';
import '../screens/semi_annual_audit_entry_screen.dart';
import '../screens/budget_entry_screen.dart';
import '../screens/reimbursement_approval_screen.dart';
import '../screens/reimbursement_gk_approval_screen.dart';
import '../screens/reimbursement_payment_screen.dart';


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
  bool isGeneratingPeriodReport = false;
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

  bool _hasReimbursementApprovalAccess() {
    return (_userProfile?.councilRoles.any((role) => 
      role.name == 'financialSecretary' || 
      role.name == 'grandKnight' || 
      role.name == 'treasurer') ?? false) ||
           (_userProfile?.assemblyRoles.any((role) => 
      role.name == 'faithfulComptroller' || 
      role.name == 'faithfulNavigator' || 
      role.name == 'faithfulPurser') ?? false);
  }

  bool _hasFinancialOfficerAccess() {
    return (_userProfile?.councilRoles.any((role) => role.name == 'financialSecretary') ?? false) ||
           (_userProfile?.assemblyRoles.any((role) => role.name == 'faithfulComptroller') ?? false);
  }

  bool _hasGrandKnightAccess() {
    return (_userProfile?.councilRoles.any((role) => role.name == 'grandKnight') ?? false) ||
           (_userProfile?.assemblyRoles.any((role) => role.name == 'faithfulNavigator') ?? false);
  }

  bool _hasTreasurerAccess() {
    return (_userProfile?.councilRoles.any((role) => role.name == 'treasurer') ?? false) ||
           (_userProfile?.assemblyRoles.any((role) => role.name == 'faithfulPurser') ?? false);
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
                      Card(
                        child: Padding(
                          padding: AppTheme.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semi-Annual Audit Report',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppTheme.smallSpacing),
                              Text(
                                'Generate the Semi-Annual Audit',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing),
                              FilledButton.icon(
                                onPressed: isGeneratingPeriodReport ? null : () async {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SemiAnnualAuditEntryScreen(),
                                    ),
                                  );
                                },
                                style: AppTheme.filledButtonStyle,
                                icon: isGeneratingPeriodReport
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.summarize),
                                label: Text(isGeneratingPeriodReport ? 'Generating...' : 'Generate Audit Report'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                      if (organizationId.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: AppTheme.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Annual Budget',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppTheme.smallSpacing),
                                Text(
                                  'Generate or edit the annual budget for the upcoming year.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacing),
                                FilledButton.icon(
                                  onPressed: _isLoading ? null : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => BudgetEntryScreen(
                                          organizationId: organizationId,
                                          userProfile: _userProfile!,
                                          year: (DateTime.now().year + 1).toString(),
                                          isFullAccess: _hasFinancialAccess(),
                                        ),
                                      ),
                                    );
                                  },
                                  style: AppTheme.filledButtonStyle,
                                  icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.edit),
                                  label: Text(_isLoading ? 'Loading...' : 'Generate/Edit Budget'),
                                ),
                              ],
                            ),
                          ),
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
                    if (_hasReimbursementApprovalAccess()) ...[
                      const Divider(),
                      Card(
                        child: Padding(
                          padding: AppTheme.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reimbursement Approvals',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppTheme.smallSpacing),
                              Text(
                                'Manage reimbursement requests and approvals',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing),
                              if (_hasFinancialOfficerAccess()) ...[
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const ReimbursementApprovalScreen(),
                                      ),
                                    );
                                  },
                                  style: AppTheme.filledButtonStyle,
                                  icon: const Icon(Icons.approval),
                                  label: const Text('Financial Officer Approvals'),
                                ),
                                const SizedBox(height: AppTheme.smallSpacing),
                              ],
                              if (_hasGrandKnightAccess()) ...[
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const ReimbursementGkApprovalScreen(),
                                      ),
                                    );
                                  },
                                  style: AppTheme.filledButtonStyle,
                                  icon: const Icon(Icons.verified_user),
                                  label: const Text('Grand Knight Voucher Approvals'),
                                ),
                                const SizedBox(height: AppTheme.smallSpacing),
                              ],
                              if (_hasTreasurerAccess()) ...[
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const ReimbursementPaymentScreen(),
                                      ),
                                    );
                                  },
                                  style: AppTheme.filledButtonStyle,
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Treasurer Payment Processing'),
                                ),
                              ],
                            ],
                          ),
                        ),
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