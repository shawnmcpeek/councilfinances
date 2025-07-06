import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/budget_entry.dart';
import '../services/budget_service.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../providers/organization_provider.dart';
import '../components/organization_toggle.dart';
import '../reports/annual_budget_report_service.dart';

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
    _selectedYear = DateTime.now().year.toString(); // Default to current year
    _loadBudget();
  }

  @override
  void dispose() {
    for (var controller in _incomeControllers.values) {
      controller.removeListener(_updateTotals);
      controller.dispose();
    }
    for (var controller in _expenseControllers.values) {
      controller.removeListener(_updateTotals);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIsAssembly = Provider.of<OrganizationProvider>(context).isAssembly;
    if (newIsAssembly != _isAssembly) {
      setState(() {
        _isAssembly = newIsAssembly;
        _isLoading = true;
      });
      _loadBudget();
    }
  }

  void _updateTotals() {
    setState(() {}); // Trigger rebuild to update totals
  }

  Future<void> _loadBudget() async {
    try {
      setState(() => _isLoading = true);
      
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

      // If no entries exist for this year, try to copy from previous year
      if (entries.isEmpty) {
        final previousYear = (int.parse(_selectedYear) - 1).toString();
        final previousEntries = await _budgetService.getBudgetEntries(
          widget.organizationId,
          _isAssembly,
          previousYear,
        );
        
        if (previousEntries.isNotEmpty) {
          await _budgetService.copyPreviousYearBudget(
            widget.organizationId,
            _isAssembly,
            previousYear,
            _selectedYear,
          );
          // Reload entries after copying
          entries.addAll(await _budgetService.getBudgetEntries(
            widget.organizationId,
            _isAssembly,
            _selectedYear,
          ));
        }
      }

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
        final incomeController = TextEditingController(
          text: entry.income.toStringAsFixed(2),
        );
        final expenseController = TextEditingController(
          text: entry.expenses.toStringAsFixed(2),
        );
        
        // Add listeners for instant total updates
        incomeController.addListener(_updateTotals);
        expenseController.addListener(_updateTotals);
        
        _incomeControllers[program.name] = incomeController;
        _expenseControllers[program.name] = expenseController;
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
          SnackBar(content: Text('Error saving budget: \\${e.toString()}')),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitBudget() async {
    if (mounted) {
      final submittingToast = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting...'), duration: Duration(days: 1)),
      );
    }
    try {
      setState(() => _isSubmitting = true);
      await _budgetService.submitBudget(
        widget.organizationId,
        _isAssembly,
        _selectedYear,
      );
      setState(() => _isSubmitted = true);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget submitted successfully')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error submitting budget', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting budget: \\${e.toString()}')),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _showSubmitWarningDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Annual Budget'),
        content: const Text('Once the Annual Budget is submitted, you will not be able to make changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildNumberInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        hintText: '0.00',
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

    final canExport = !_isSaving && (_budgetEntries.isNotEmpty);

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
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedYear,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  items: () {
                    final now = DateTime.now().year;
                    final selected = int.tryParse(_selectedYear) ?? now;
                    final years = <int>{};
                    for (int i = -2; i <= 4; i++) {
                      years.add(now + i);
                    }
                    years.add(selected); // Always include selected year
                    final sortedYears = years.toList()..sort();
                    return sortedYears.map((year) => DropdownMenuItem(
                      value: year.toString(),
                      child: Text(year.toString()),
                    )).toList();
                  }(),
                  onChanged: (value) {
                    print('Dropdown changed: $value');
                    if (value != null) {
                      setState(() => _selectedYear = value);
                      _loadBudget();
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                ),
              ),
            ),
            OrganizationToggle(
              onChanged: (isAssembly) async {
                setState(() {
                  _isAssembly = isAssembly;
                  _isLoading = true;
                });
                await _loadBudget();
              },
            ),
            const SizedBox(height: 16),
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
                      onPressed: _isSubmitting ? null : () async {
                        final confirm = await _showSubmitWarningDialog();
                        if (!confirm) return;
                        await _saveBudget();
                        await _submitBudget();
                      },
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canExport ? () async {
                        final service = AnnualBudgetReportService();
                        await service.generateAnnualBudgetReport(
                          organizationId: widget.organizationId,
                          year: _selectedYear,
                          entries: _incomeControllers.keys.map((programName) {
                            final income = double.tryParse(_incomeControllers[programName]?.text ?? '0') ?? 0;
                            final expenses = double.tryParse(_expenseControllers[programName]?.text ?? '0') ?? 0;
                            return BudgetEntry(
                              id: '',
                              programName: programName,
                              income: income,
                              expenses: expenses,
                              createdAt: DateTime.now(),
                              createdBy: '',
                            );
                          }).toList(),
                          status: _isSubmitted ? 'Submitted' : 'Draft',
                        );
                      } : null,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export/Print/Share'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: int.parse(_selectedYear) > DateTime.now().year - 2 ? () async {
                      final previousYear = (int.parse(_selectedYear) - 1).toString();
                      await _budgetService.copyPreviousYearBudget(
                        widget.organizationId,
                        _isAssembly,
                        previousYear,
                        _selectedYear,
                      );
                      await _loadBudget();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied budget from $previousYear to $_selectedYear')),
                        );
                      }
                    } : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Previous Year'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      ),
    );
  }
} 