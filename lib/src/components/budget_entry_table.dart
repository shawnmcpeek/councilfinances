import 'package:flutter/material.dart';
import '../models/program.dart';
import '../services/budget_service.dart';
import '../services/program_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/report_file_saver.dart';
import 'package:pdf/pdf.dart';
import 'organization_toggle.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../providers/user_provider.dart';

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
    // Debug output
    final now = DateTime.now();
    final budgetYear = int.tryParse(widget.year) ?? 0;
    final lockDate = DateTime(budgetYear, 1, 1);
    final isDateLocked = now.isAfter(lockDate) || now.isAtSameMomentAs(lockDate);
    final isStatusLocked = entries.isNotEmpty && entries.first.status == 'finalized';
    // Print debug info
    // ignore: avoid_print
    print('DEBUG: Budget year: ${widget.year}, Now: $now, Lock date: $lockDate, isDateLocked: $isDateLocked, isStatusLocked: $isStatusLocked, status: ${entries.isNotEmpty ? entries.first.status : 'none'}');
    _isLocked = isDateLocked;
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
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
    try {
      final pdf = pw.Document();
      // Calculate totals
      double totalExpenses = 0;
      double totalIncome = 0;
      for (final program in _programs) {
        final expense = double.tryParse(_expenseControllers[program.id]?.text ?? '0.00') ?? 0.0;
        final income = double.tryParse(_incomeControllers[program.id]?.text ?? '0.00') ?? 0.0;
        totalExpenses += expense;
        totalIncome += income;
      }
      final profitLoss = totalIncome - totalExpenses;
      // Determine organization name and ID for header and file name
      final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isAssembly = organizationProvider.isAssembly;
      final userProfile = userProvider.userProfile ?? widget.userProfile;
      final organizationId = userProfile.getOrganizationId(isAssembly);
      String orgName = isAssembly
          ? 'Assembly ${userProfile.assemblyNumber}'
          : 'Council ${userProfile.councilNumber}';
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Budget for $orgName Fiscal Year ${widget.year}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
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
                    // Totals row
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalExpenses.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalIncome.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    // Profit/Loss row
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PROFIT / LOSS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('')),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            (profitLoss >= 0 ? '+' : '') + profitLoss.toStringAsFixed(2),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: profitLoss >= 0
                                  ? PdfColor.fromInt(0xFF388E3C)
                                  : PdfColor.fromInt(0xFFD32F2F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      final pdfBytes = await pdf.save();
      // Use platform-specific file saver
      await saveOrShareFile(
        pdfBytes,
        'budget_${organizationId}_${widget.year}.pdf',
        'Budget for $orgName Fiscal Year ${widget.year}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrganizationProvider, UserProvider>(
      builder: (context, organizationProvider, userProvider, child) {
        final userProfile = userProvider.userProfile ?? widget.userProfile;
        final isAssembly = organizationProvider.isAssembly;
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
                OrganizationToggle(
                  userProfile: userProfile,
                  isAssembly: isAssembly,
                  onChanged: (newIsAssembly) async {
                    context.read<OrganizationProvider>().setOrganization(newIsAssembly);
                    setState(() => _isLoading = true);
                    await _loadData();
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Annual Budget for ${widget.year}', style: Theme.of(context).textTheme.titleLarge),
                    // Replace PDF icon with Print Budget button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _exportPDF,
                            icon: const Icon(Icons.print),
                            label: const Text('Print Budget'),
                          ),
                        ),
                      ],
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
                            color: WidgetStateProperty.all(Colors.grey[200]),
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
                      _isLocked
                        ? (DateTime.now().isAfter(DateTime(int.parse(widget.year), 1, 1))
                            ? 'This budget is locked because it is now ${DateTime.now()} and the lock date for ${widget.year} is ${DateTime(int.parse(widget.year), 1, 1)}.'
                            : 'This budget is locked because its status is finalized.')
                        : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 