import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/program_dropdown.dart';
import '../services/finance_service.dart';
import '../models/program.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';

class ProgramBudget extends StatefulWidget {
  final String organizationId;

  const ProgramBudget({
    super.key,
    required this.organizationId,
  });

  @override
  State<ProgramBudget> createState() => _ProgramBudgetState();
}

class _ProgramBudgetState extends State<ProgramBudget> {
  final _financeService = FinanceService();
  Program? _selectedProgram;
  String? _selectedYear;
  bool _isCalculating = false;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    // Set default year to current year
    _selectedYear = DateTime.now().year.toString();
  }

  List<String> get _availableYears {
    final currentYear = DateTime.now().year;
    return [
      (currentYear - 1).toString(),
      currentYear.toString(),
    ];
  }

  Future<void> _calculateBudget() async {
    if (_selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _hasCalculated = false;
    });

    try {
      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      
      // Get all financial entries for the selected program and year
      final entries = await _financeService.getFinanceEntriesForProgram(
        widget.organizationId,
        isAssembly,
        _selectedProgram!.id,
        _selectedYear!,
      );

      double income = 0;
      double expenses = 0;

      // Calculate totals
      for (var entry in entries) {
        if (!entry.isExpense) {
          income += entry.amount;
        } else {
          expenses += entry.amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpenses = expenses;
          _isCalculating = false;
          _hasCalculated = true;
        });
      }
    } catch (e) {
      AppLogger.error('Error calculating program budget', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating budget: ${e.toString()}')),
        );
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  Widget _buildResults() {
    if (!_hasCalculated) return const SizedBox.shrink();

    final netAmount = _totalIncome - _totalExpenses;
    final isProfit = netAmount >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacing),
        const Divider(),
        const SizedBox(height: AppTheme.spacing),
        Text(
          'Budget Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        _buildSummaryRow('Total Income:', _totalIncome),
        const SizedBox(height: AppTheme.smallSpacing),
        _buildSummaryRow('Total Expenses:', _totalExpenses),
        const SizedBox(height: AppTheme.smallSpacing),
        _buildSummaryRow(
          isProfit ? 'Net Profit:' : 'Net Loss:',
          netAmount.abs(),
          isProfit ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program Budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Calculate program income and expenses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            ProgramDropdown(
              organizationId: widget.organizationId,
              isAssembly: context.watch<OrganizationProvider>().isAssembly,
              selectedProgram: _selectedProgram,
              onChanged: (program) {
                setState(() {
                  _selectedProgram = program;
                  _hasCalculated = false;
                });
              },
            ),
            const SizedBox(height: AppTheme.spacing),
            DropdownButtonFormField<String>(
              decoration: AppTheme.formFieldDecoration.copyWith(
                labelText: 'Year',
              ),
              value: _selectedYear,
              items: _availableYears.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    _hasCalculated = false;
                  });
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing),
            FilledButton.icon(
              onPressed: _isCalculating ? null : _calculateBudget,
              style: AppTheme.filledButtonStyle,
              icon: _isCalculating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.summarize),
              label: Text(_isCalculating ? 'Calculating...' : 'Calculate Budget'),
            ),
            _buildResults(),
          ],
        ),
      ),
    );
  }
} 