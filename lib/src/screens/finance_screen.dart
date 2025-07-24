import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'finance/income_entry.dart';
import 'finance/expense_entry.dart';
import 'finance/transaction_history.dart';
import '../providers/organization_provider.dart';
import '../providers/user_provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  VoidCallback? _refreshTransactionHistory;

  @override
  void initState() {
    super.initState();
    // Ensure user profile is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
    });
  }

  void _refreshTransactions() {
    _refreshTransactionHistory?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
      ),
      body: Consumer2<OrganizationProvider, UserProvider>(
        builder: (context, organizationProvider, userProvider, child) {
          final organizationId = userProvider.getOrganizationId(organizationProvider.isAssembly);
          
          if (userProvider.userProfile == null || organizationId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: AppTheme.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Income Entry
                IncomeEntry(
                  organizationId: organizationId,
                  onEntryAdded: _refreshTransactions,
                ),
                const SizedBox(height: AppTheme.spacing),
                
                // Expense Entry
                ExpenseEntry(
                  organizationId: organizationId,
                  onEntryAdded: _refreshTransactions,
                ),
                const SizedBox(height: AppTheme.spacing),
                
                // Transaction History
                TransactionHistory(
                  organizationId: organizationId,
                  ref: _refreshTransactionHistory,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
