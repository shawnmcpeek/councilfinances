import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/program_dropdown.dart';
import '../services/finance_service.dart';
import '../services/budget_service.dart';
import '../models/program.dart';
import '../models/budget_entry.dart';
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
  final _budgetService = BudgetService();
  Program? _selectedProgram;
  String? _selectedYear;
  bool _isCalculating = false;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  bool _hasCalculated = false;
  BudgetEntry? _approvedBudget;

  @override
  void initState() {
    super.initState();
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

      // Get approved budget for the program
      _approvedBudget = await _budgetService.getBudgetEntry(
        widget.organizationId,
        isAssembly,
        _selectedYear!,
        _selectedProgram!.name,
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

    final approvedIncome = _approvedBudget?.income ?? 0;
    final approvedExpenses = _approvedBudget?.expenses ?? 0;
    final remainingIncome = approvedIncome - _totalIncome;
    final remainingExpenses = approvedExpenses - _totalExpenses;
    final netAmount = _totalIncome - _totalExpenses;
    final approvedNet = approvedIncome - approvedExpenses;
    final remainingNet = remainingIncome - remainingExpenses;

    TextStyle headerStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold);
    TextStyle valueStyle = Theme.of(context).textTheme.bodyLarge!;
    TextStyle positiveStyle = valueStyle.copyWith(color: Colors.green, fontWeight: FontWeight.bold);
    TextStyle negativeStyle = valueStyle.copyWith(color: Colors.red, fontWeight: FontWeight.bold);

    Widget valueCell(double value) {
      final style = value == 0
          ? valueStyle
          : value > 0
              ? positiveStyle
              : negativeStyle;
      return Align(
        alignment: Alignment.center,
        child: Text(
          '${value.toStringAsFixed(2)}',
          style: style,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacing),
        const Divider(),
        const SizedBox(height: AppTheme.spacing),
        Text('Budget Summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacing),
        // Header row
        Row(
          children: [
            Expanded(flex: 2, child: SizedBox()),
            Expanded(child: Text('Approved', style: headerStyle, textAlign: TextAlign.center)),
            Expanded(child: Text('Current', style: headerStyle, textAlign: TextAlign.center)),
            Expanded(child: Text('Remaining', style: headerStyle, textAlign: TextAlign.center)),
          ],
        ),
        const SizedBox(height: 8),
        // Income row
        Row(
          children: [
            Expanded(flex: 2, child: Text('Income', style: headerStyle)),
            Expanded(child: valueCell(approvedIncome)),
            Expanded(child: valueCell(_totalIncome)),
            Expanded(child: valueCell(remainingIncome)),
          ],
        ),
        const SizedBox(height: 8),
        // Expenses row
        Row(
          children: [
            Expanded(flex: 2, child: Text('Expenses', style: headerStyle)),
            Expanded(child: valueCell(approvedExpenses)),
            Expanded(child: valueCell(_totalExpenses)),
            Expanded(child: valueCell(remainingExpenses)),
          ],
        ),
        const SizedBox(height: 8),
        // Net row
        Row(
          children: [
            Expanded(flex: 2, child: Text('Net', style: headerStyle)),
            Expanded(child: valueCell(approvedNet)),
            Expanded(child: valueCell(netAmount)),
            Expanded(child: valueCell(remainingNet)),
          ],
        ),
        const SizedBox(height: AppTheme.spacing),
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
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(
              width: double.infinity,
              child: ProgramDropdown(
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
            ),
            const SizedBox(height: AppTheme.spacing),
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
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
            ),
            const SizedBox(height: AppTheme.spacing),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
            ),
            _buildResults(),
          ],
        ),
      ),
    );
  }
} 