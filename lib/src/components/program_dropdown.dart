import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/program.dart';
import '../services/program_service.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/program_provider.dart';

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
  late final VoidCallback _providerListener;

  @override
  void initState() {
    super.initState();
    _providerListener = () {
      _loadPrograms();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgramProvider>(context, listen: false).addListener(_providerListener);
    });
    _loadPrograms();
  }

  @override
  void dispose() {
    Provider.of<ProgramProvider>(context, listen: false).removeListener(_providerListener);
    super.dispose();
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
          program.isAssembly == widget.isAssembly &&
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
    
    return DropdownButtonFormField<Program>(
      decoration: AppTheme.formFieldDecorationWithLabel('Program', 'Select a program'),
      value: widget.selectedProgram,
      items: programs.map((program) {
        return DropdownMenuItem(
          value: program,
          child: Text(program.name),
        );
      }).toList(),
      onChanged: widget.onChanged,
      validator: widget.validator,
      isExpanded: true,
    );
  }
} 