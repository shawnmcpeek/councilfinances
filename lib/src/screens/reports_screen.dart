import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../components/organization_toggle.dart';
import '../components/program_budget.dart';
import '../reports/form1728_report.dart';
import '../reports/volunteer_hours_report.dart';
import '../reports/balance_sheet_report.dart';
import '../reports/annual_budget_report.dart';
import '../providers/organization_provider.dart';
import '../reports/semi_annual_audit_service.dart';
import '../models/member_roles.dart';
import '../components/semi_annual_audit_selector.dart';
import '../screens/semi_annual_audit_entry_screen.dart';
import '../screens/view_filtered_programs_screen.dart';

import '../services/finance_service.dart';
import '../utils/logger.dart';

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
  bool isGeneratingBalanceSheet = false;
  bool isGeneratingAnnualBudget = false;
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
      final profile = await _userService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user profile', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getOrganizationId() {
    if (_userProfile == null) return '';
    final isAssembly = context.read<OrganizationProvider>().isAssembly;
    return _userProfile!.getOrganizationId(isAssembly);
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
    final organizationId = _getOrganizationId();

    if (organizationId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please select an organization')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OrganizationToggle(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    if (_hasFinancialAccess()) ...[
                      BalanceSheetReport(
                        organizationId: organizationId,
                        selectedYear: selectedYear,
                        isGenerating: isGeneratingBalanceSheet,
                        onGeneratingChange: (value) => setState(() => isGeneratingBalanceSheet = value),
                        onYearChange: (value) => setState(() => selectedYear = value),
                      ),
                      const SizedBox(height: AppTheme.spacing),
                      AnnualBudgetReport(
                        organizationId: organizationId,
                        selectedYear: selectedYear,
                        isGenerating: isGeneratingAnnualBudget,
                        onGeneratingChange: (value) => setState(() => isGeneratingAnnualBudget = value),
                        onYearChange: (value) => setState(() => selectedYear = value),
                      ),
                      const SizedBox(height: AppTheme.spacing),
                      Card(
                        child: Padding(
                          padding: AppTheme.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
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
                      const SizedBox(height: AppTheme.spacing),
                      if (organizationId.isNotEmpty)
                        ProgramBudget(
                          organizationId: organizationId,
                        ),
                      const SizedBox(height: 24),
                      const Divider(),
                    ],
                    if (_hasVolunteerAccess() && _userProfile!.uid != null) ...[
                      VolunteerHoursReport(
                        userId: _userProfile!.uid,
                        organizationId: organizationId,
                        selectedYear: selectedYear,
                        isGenerating: isGeneratingVolunteerHours,
                        onGeneratingChange: (value) => setState(() => isGeneratingVolunteerHours = value),
                        onYearChange: (value) => setState(() => selectedYear = value),
                      ),
                    ],
                    Card(
                      child: Padding(
                        padding: AppTheme.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Filtered Programs',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            Text(
                              'View all active system and custom programs for this organization',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ViewFilteredProgramsScreen(
                                        organizationId: _getOrganizationId(),
                                        isAssembly: context.read<OrganizationProvider>().isAssembly,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.filter_alt),
                                label: const Text('View Filtered Programs'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, Map<int, Map<String, double>>>> _calculateGridData(String organizationId) async {
    final financeService = FinanceService();
    final entries = await financeService.getFinanceEntriesForYear(
      organizationId,
      context.read<OrganizationProvider>().isAssembly,
      selectedYear,
    );
    
    final gridData = <String, Map<int, Map<String, double>>>{};
    
    for (var entry in entries) {
      final category = entry.program.category;
      final month = entry.date.month;
      
      gridData.putIfAbsent(category, () => {});
      gridData[category]!.putIfAbsent(month, () => {
        'income': 0.0,
        'expense': 0.0,
      });
      
      final type = entry.isExpense ? 'expense' : 'income';
      gridData[category]![month]![type] = 
        (gridData[category]![month]![type] ?? 0.0) + entry.amount;
    }
    
    return gridData;
  }

  Future<Map<String, double>> _calculateCategoryTotals(String organizationId) async {
    final gridData = await _calculateGridData(organizationId);
    final totals = <String, Map<String, double>>{};
    
    for (var category in gridData.keys) {
      totals[category] = {'income': 0.0, 'expense': 0.0};
      
      for (var monthData in gridData[category]!.values) {
        totals[category]!['income'] = 
          (totals[category]!['income'] ?? 0.0) + (monthData['income'] ?? 0.0);
        totals[category]!['expense'] = 
          (totals[category]!['expense'] ?? 0.0) + (monthData['expense'] ?? 0.0);
      }
    }

    return totals.map((category, data) => 
      MapEntry(category, (data['income'] ?? 0.0) - (data['expense'] ?? 0.0)));
  }

  Future<Map<int, Map<String, double>>> _calculateMonthTotals(String organizationId) async {
    final gridData = await _calculateGridData(organizationId);
    final totals = <int, Map<String, double>>{};
    
    for (var categoryData in gridData.values) {
      for (var month in categoryData.keys) {
        totals.putIfAbsent(month, () => {'income': 0.0, 'expense': 0.0});
        
        totals[month]!['income'] = 
          (totals[month]!['income'] ?? 0.0) + (categoryData[month]!['income'] ?? 0.0);
        totals[month]!['expense'] = 
          (totals[month]!['expense'] ?? 0.0) + (categoryData[month]!['expense'] ?? 0.0);
      }
    }

    return totals;
  }
}