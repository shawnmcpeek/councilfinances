import 'package:flutter/material.dart';
import '../models/program.dart';
import '../services/budget_service.dart';
import '../services/program_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BudgetEntryTable extends StatefulWidget {
  final String organizationId;
  final UserProfile userProfile;
  final String year;
  final bool isFullAccess;

  const BudgetEntryTable({
    super.key,
    required this.organizationId,
    required this.userProfile,
    required this.year,
    required this.isFullAccess,
  });

  @override
  State<BudgetEntryTable> createState() => _BudgetEntryTableState();
}

class _BudgetEntryTableState extends State<BudgetEntryTable> {
  final BudgetService _budgetService = BudgetService();
  final ProgramService _programService = ProgramService();
  List<Program> _programs = [];
  final Map<String, TextEditingController> _expenseControllers = {};
  final Map<String, TextEditingController> _incomeControllers = {};
  final Map<String, double> _prevYearExpenses = {};
  final Map<String, double> _prevYearIncome = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSubmitting = false;
  bool _isLocked = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final isAssembly = widget.organizationId.startsWith('A');
    final programsData = await _programService.loadSystemPrograms();
    await _programService.loadProgramStates(programsData, widget.organizationId);
    final customPrograms = await _programService.getCustomPrograms(widget.organizationId);
    final List<Program> enabledPrograms = [];
    final programsMap = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
    for (var categoryPrograms in programsMap.values) {
      enabledPrograms.addAll(categoryPrograms.where((p) => p.isEnabled));
    }
    enabledPrograms.addAll(customPrograms.where((p) => p.isEnabled));
    enabledPrograms.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _programs = enabledPrograms;
    // Load current and previous year budget entries
    final entries = await _budgetService.getBudgetEntries(widget.organizationId, widget.year);
    final prevEntries = await _budgetService.getPreviousYearBudgetEntries(widget.organizationId, (int.parse(widget.year) - 1).toString());
    for (final program in _programs) {
      BudgetEntry? entry;
      try {
        entry = entries.firstWhere((e) => e.programId == program.id);
      } catch (_) {
        entry = null;
      }
      BudgetEntry? prevEntry;
      try {
        prevEntry = prevEntries.firstWhere((e) => e.programId == program.id);
      } catch (_) {
        prevEntry = null;
      }
      _expenseControllers[program.id] = TextEditingController(text: entry != null ? entry.expenses.toStringAsFixed(2) : '');
      _incomeControllers[program.id] = TextEditingController(text: entry != null ? entry.income.toStringAsFixed(2) : '');
      _prevYearExpenses[program.id] = prevEntry?.expenses ?? 0.0;
      _prevYearIncome[program.id] = prevEntry?.income ?? 0.0;
    }
    _isLocked = _budgetService.isBudgetLocked(widget.year) || (entries.isNotEmpty && entries.first.status == 'finalized');
    setState(() => _isLoading = false);
  }

  void _autofillFromPreviousYear() {
    for (final program in _programs) {
      _expenseControllers[program.id]?.text = _prevYearExpenses[program.id]?.toStringAsFixed(2) ?? '0.00';
      _incomeControllers[program.id]?.text = _prevYearIncome[program.id]?.toStringAsFixed(2) ?? '0.00';
    }
    setState(() => _hasChanges = true);
  }

  Future<void> _saveAll() async {
    setState(() { _isSaving = true; });
    final now = DateTime.now();
    final userId = widget.userProfile.uid;
    final entries = _programs.map((program) => BudgetEntry(
      id: '${widget.organizationId}_${program.id}_${widget.year}',
      organizationId: widget.organizationId,
      programId: program.id,
      year: widget.year,
      income: double.tryParse(_incomeControllers[program.id]?.text ?? '') ?? 0.0,
      expenses: double.tryParse(_expenseControllers[program.id]?.text ?? '') ?? 0.0,
      createdAt: now,
      updatedAt: now,
      createdBy: userId,
      updatedBy: userId,
      status: 'draft',
    )).toList();
    await _budgetService.upsertBudgetEntries(entries);
    setState(() { _isSaving = false; _hasChanges = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved.')),
      );
    }
  }

  Future<void> _submitBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Budget'),
        content: const Text('Submitting these budget numbers will finalize them on January 1. After that, they cannot be changed. Are you sure you want to submit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      await _saveAll();
      await _budgetService.finalizeBudget(widget.organizationId, widget.year);
      setState(() { _isSubmitting = false; _isLocked = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget submitted and finalized.')),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Budget for ${widget.year}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Program Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Planned Expense', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Planned Income', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ..._programs.map((program) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(program.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_expenseControllers[program.id]?.text ?? '0.00')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_incomeControllers[program.id]?.text ?? '0.00')),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/budget_${widget.organizationId}_${widget.year}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Budget for ${widget.year}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Group programs by category
    final Map<String, List<Program>> programsByCategory = {};
    for (final program in _programs) {
      final category = program.category;
      programsByCategory.putIfAbsent(category, () => []).add(program);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Annual Budget for ${widget.year}', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export as PDF',
                  onPressed: _exportPDF,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _autofillFromPreviousYear,
                    icon: const Icon(Icons.copy),
                    label: const Text('Autofill from Previous Year'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (!_hasChanges || _isLocked || _isSaving) ? null : _saveAll,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_isLocked || _isSubmitting) ? null : _submitBudget,
                    icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.check_circle),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit Budget'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Program Name')),
                  DataColumn(label: Text('Planned Expense')),
                  DataColumn(label: Text('Planned Income')),
                ],
                rows: [
                  for (final category in programsByCategory.keys)
                    ...[
                      DataRow(
                        color: MaterialStateProperty.all(Colors.grey[200]),
                        cells: [
                          DataCell(Text(
                            category[0].toUpperCase() + category.substring(1).toLowerCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          const DataCell(SizedBox()),
                          const DataCell(SizedBox()),
                        ],
                      ),
                      ...programsByCategory[category]!.map((program) {
                        final isEditable = widget.isFullAccess && !_isLocked;
                        return DataRow(
                          cells: [
                            DataCell(Text(program.name)),
                            DataCell(
                              TextField(
                                controller: _expenseControllers[program.id],
                                enabled: isEditable,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: _prevYearExpenses[program.id]?.toStringAsFixed(2) ?? '0.00',
                                  border: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() => _hasChanges = true),
                              ),
                            ),
                            DataCell(
                              TextField(
                                controller: _incomeControllers[program.id],
                                enabled: isEditable,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: _prevYearIncome[program.id]?.toStringAsFixed(2) ?? '0.00',
                                  border: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() => _hasChanges = true),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                ],
              ),
            ),
            if (_isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'This budget is finalized and cannot be changed after January 1 of the budget year.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 