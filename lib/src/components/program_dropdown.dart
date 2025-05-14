import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/program.dart';
import '../services/program_service.dart';
import '../utils/logger.dart';
import 'package:dropdown_search/dropdown_search.dart';

class ProgramDropdown extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;
  final FinancialType? filterType;
  final Program? selectedProgram;
  final Function(Program?) onChanged;
  final String? Function(Program?)? validator;

  const ProgramDropdown({
    super.key,
    required this.organizationId,
    required this.isAssembly,
    this.filterType,
    this.selectedProgram,
    required this.onChanged,
    this.validator,
  });

  @override
  State<ProgramDropdown> createState() => _ProgramDropdownState();
}

class _ProgramDropdownState extends State<ProgramDropdown> {
  final _programService = ProgramService();
  bool _isLoading = true;
  ProgramsData? _systemPrograms;
  List<Program>? _customPrograms;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    if (widget.organizationId.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      // Load system programs if we haven't yet
      _systemPrograms ??= await _programService.loadSystemPrograms();
      
      // Load program states and custom programs
      await _programService.loadProgramStates(_systemPrograms!, widget.organizationId, widget.isAssembly);
      final customPrograms = await _programService.getCustomPrograms(widget.organizationId, widget.isAssembly);

      if (mounted) {
        setState(() {
          _customPrograms = customPrograms;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading programs', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Program> _getEnabledPrograms() {
    if (_systemPrograms == null) return [];
    
    final List<Program> enabledPrograms = [];
    
    // Add system programs
    final programs = widget.isAssembly 
        ? _systemPrograms?.assemblyPrograms ?? {}
        : _systemPrograms?.councilPrograms ?? {};
    
    for (var categoryPrograms in programs.values) {
      enabledPrograms.addAll(
        categoryPrograms.where((program) => 
          program.isEnabled && 
          (widget.filterType == null || 
           program.financialType == widget.filterType ||
           program.financialType == FinancialType.both)
        )
      );
    }
    
    // Add custom programs
    if (_customPrograms != null) {
      enabledPrograms.addAll(
        _customPrograms!.where((program) => 
          program.isEnabled &&
          (widget.filterType == null || 
           program.financialType == widget.filterType ||
           program.financialType == FinancialType.both)
        )
      );
    }
    
    // Sort alphabetically by name
    enabledPrograms.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    return enabledPrograms;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final programs = _getEnabledPrograms();
    
    return DropdownSearch<Program>(
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Search programs',
            hintText: 'Type to search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      items: programs,
      itemAsString: (Program program) => program.name,
      onChanged: widget.onChanged,
      selectedItem: widget.selectedProgram,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: AppTheme.formFieldDecorationWithLabel('Program', 'Select a program'),
      ),
      validator: widget.validator,
      compareFn: (Program p1, Program p2) => p1.id == p2.id,
    );
  }
} 