import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../components/organization_toggle.dart';
import 'finance/income_entry.dart';
import 'finance/expense_entry.dart';
import 'finance/transaction_history.dart';
import '../providers/organization_provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
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
      final userProfile = await UserService().getCurrentUserProfile();
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading user profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
      ),
      body: Consumer<OrganizationProvider>(
        builder: (context, organizationProvider, child) {
          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AppTheme.screenContent(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const OrganizationToggle(),
                        SizedBox(height: AppTheme.spacing),
                        IncomeEntry(
                          isAssembly: organizationProvider.isAssembly,
                          organizationId: _userProfile?.getOrganizationId(
                            organizationProvider.isAssembly,
                          ) ?? '',
                        ),
                        SizedBox(height: AppTheme.spacing),
                        ExpenseEntry(
                          isAssembly: organizationProvider.isAssembly,
                          organizationId: _userProfile?.getOrganizationId(
                            organizationProvider.isAssembly,
                          ) ?? '',
                        ),
                        SizedBox(height: AppTheme.spacing),
                        TransactionHistory(
                          isAssembly: organizationProvider.isAssembly,
                          organizationId: _userProfile?.getOrganizationId(
                            organizationProvider.isAssembly,
                          ) ?? '',
                        ),
                        SizedBox(height: AppTheme.spacing),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
