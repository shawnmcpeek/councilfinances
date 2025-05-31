import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/budget_entry.dart';
import '../services/budget_service.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../providers/organization_provider.dart';

class AnnualBudgetScreen extends StatefulWidget {
  final String organizationId;

  const AnnualBudgetScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<AnnualBudgetScreen> createState() => _AnnualBudgetScreenState();
}

class _AnnualBudgetScreenState extends State<AnnualBudgetScreen> {
  final _budgetService = BudgetService();
  final _programService = ProgramService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String _selectedYear = DateTime.now().year.toString();
  List<BudgetEntry> _budgetEntries = [];
  final Map<String, TextEditingController> _incomeControllers = {};
  final Map<String, TextEditingController> _expenseControllers = {};
  bool _isAssembly = false;

  @override
  void initState() {
    super.initState();
    _isAssembly = Provider.of<OrganizationProvider>(context, listen: false).isAssembly;
    _loadBudget();
  }

  @override
  void dispose() {
    for (var controller in _incomeControllers.values) {
      controller.dispose();
    }
    for (var controller in _expenseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBudget() async {
    try {
      setState(() => _isLoading = true);
      
      // Check if budget is already submitted
      _isSubmitted = await _budgetService.isBudgetSubmitted(
        widget.organizationId,
        _isAssembly,
        _selectedYear,
      );
      
      // Load system programs
      final programsData = await _programService.loadSystemPrograms();
      // Load program states for the organization (this updates isEnabled flags)
      await _programService.loadProgramStates(programsData, widget.organizationId, _isAssembly);
      final programs = _isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      
      // Get all active system programs
      final activeSystemPrograms = programs.values
          .expand((list) => list)
          .where((program) => program.isEnabled)
          .toList();

      // Get all active custom programs
      final customPrograms = await _programService.getCustomPrograms(widget.organizationId, _isAssembly);
      final activeCustomPrograms = customPrograms.where((program) => program.isEnabled).toList();

      // Combine and sort all active programs
      final activePrograms = [
        ...activeSystemPrograms,
        ...activeCustomPrograms,
      ]..sort((a, b) => a.name.compareTo(b.name));

      // Load existing budget entries
      final entries = await _budgetService.getBudgetEntries(
        widget.organizationId,
        _isAssembly,
        _selectedYear,
      );

      // Initialize controllers for each program
      _incomeControllers.clear();
      _expenseControllers.clear();
      for (var program in activePrograms) {
        final entry = entries.firstWhere(
          (e) => e.programName == program.name,
          orElse: () => BudgetEntry(
            id: '',
            programName: program.name,
            income: 0,
            expenses: 0,
            createdAt: DateTime.now(),
            createdBy: '',
          ),
        );
        _incomeControllers[program.name] = TextEditingController(
          text: entry.income > 0 ? entry.income.toString() : '',
        );
        _expenseControllers[program.name] = TextEditingController(
          text: entry.expenses > 0 ? entry.expenses.toString() : '',
        );
      }

      setState(() {
        _budgetEntries = entries;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error loading budget', e, stackTrace);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading budget data')),
        );
      }
    }
  }

  Future<void> _saveBudget() async {
    if (_isSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot modify a submitted budget')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      for (var programName in _incomeControllers.keys) {
        final incomeController = _incomeControllers[programName]!;
        final expenseController = _expenseControllers[programName]!;

        final income = double.tryParse(incomeController.text) ?? 0;
        final expenses = double.tryParse(expenseController.text) ?? 0;

        await _budgetService.saveBudgetEntry(
          organizationId: widget.organizationId,
          isAssembly: _isAssembly,
          year: _selectedYear,
          programName: programName,
          income: income,
          expenses: expenses,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error saving budget', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving budget: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitBudget() async {
    try {
      setState(() => _isSubmitting = true);

      await _budgetService.submitBudget(
        widget.organizationId,
        _isAssembly,
        _selectedYear,
      );

      setState(() => _isSubmitted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget submitted successfully')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error submitting budget', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting budget: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildNumberInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: !_isSubmitted,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Annual Budget')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Annual Budget'),
            if (_isSubmitted)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Submitted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedYear,
            items: List.generate(5, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem(
                value: year.toString(),
                child: Text(year.toString()),
              );
            }),
            onChanged: _isSubmitted ? null : (value) {
              if (value != null) {
                setState(() => _selectedYear = value);
                _loadBudget();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (!_isSubmitted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveBudget,
                      icon: _isSaving 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitBudget,
                      icon: _isSubmitting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Budget'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Income', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _incomeControllers.entries.map((entry) {
                  final programName = entry.key;
                  final incomeController = entry.value;
                  final expenseController = _expenseControllers[programName]!;
                  
                  final income = double.tryParse(incomeController.text) ?? 0;
                  final expenses = double.tryParse(expenseController.text) ?? 0;
                  final total = income - expenses;

                  return DataRow(
                    cells: [
                      DataCell(Text(programName)),
                      DataCell(_buildNumberInput(incomeController)),
                      DataCell(_buildNumberInput(expenseController)),
                      DataCell(
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: total >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 