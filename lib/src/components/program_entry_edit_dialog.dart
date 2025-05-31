import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/program_entry_service.dart';
import '../models/form1728p_program.dart';
import '../models/program_entry_adapter.dart';
import '../utils/logger.dart';
import '../providers/program_provider.dart';
import 'package:provider/provider.dart';

class ProgramEntryEditDialog extends StatefulWidget {
  final ProgramEntry entry;
  final String organizationId;
  final bool isAssembly;
  final VoidCallback onSuccess;

  const ProgramEntryEditDialog({
    super.key,
    required this.entry,
    required this.organizationId,
    required this.isAssembly,
    required this.onSuccess,
  });

  @override
  State<ProgramEntryEditDialog> createState() => _ProgramEntryEditDialogState();
}

class _ProgramEntryEditDialogState extends State<ProgramEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _programEntryService = ProgramEntryService();
  final _hoursController = TextEditingController();
  final _disbursementController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  
  bool _isLoading = false;
  Form1728PCategory? _selectedCategory;
  Form1728PProgram? _selectedProgram;
  DateTime _selectedDate = DateTime.now();
  final Map<Form1728PCategory, List<Form1728PProgram>> _programs = {};

  @override
  void initState() {
    super.initState();
    // Initialize form with existing entry data
    _selectedCategory = widget.entry.category;
    _selectedProgram = widget.entry.program;
    _selectedDate = widget.entry.date;
    _hoursController.text = widget.entry.hours.toString();
    _disbursementController.text = widget.entry.disbursement.toString();
    _descriptionController.text = widget.entry.description;
    _dateController.text = _formatDate(_selectedDate);
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/form1728p_programs.json');
      final jsonData = json.decode(jsonString);
      
      // Initialize programs by category
      final programsMap = <Form1728PCategory, List<Form1728PProgram>>{};
      for (var category in Form1728PCategory.values) {
        programsMap[category] = (jsonData[category.name] as List)
          .map((program) => Form1728PProgram.fromJson(program))
          .toList();
      }

      if (mounted) {
        setState(() {
          _programs.clear();
          _programs.addAll(programsMap);
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading Form 1728P programs', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading programs: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _disbursementController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _updateEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    final hours = int.tryParse(_hoursController.text);
    if (hours == null || hours < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of hours')),
      );
      return;
    }

    final disbursement = double.tryParse(_disbursementController.text);
    if (disbursement == null || disbursement < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid disbursement amount')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _programEntryService.updateProgramEntry(
        organizationId: widget.organizationId,
        entryId: widget.entry.id,
        category: _selectedCategory!,
        program: _selectedProgram!,
        hours: hours,
        disbursement: disbursement,
        description: description,
        date: _selectedDate,
      );
      
      if (mounted) {
        widget.onSuccess();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program entry updated successfully')),
        );
        Provider.of<ProgramProvider>(context, listen: false).reload();
      }
    } catch (e) {
      AppLogger.error('Error updating program entry', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating entry: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Program Entry',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.largeSpacing),
              
              // Category Dropdown
              DropdownButtonFormField<Form1728PCategory>(
                decoration: AppTheme.formFieldDecorationWithLabel('Category'),
                value: _selectedCategory,
                items: Form1728PCategory.values
                    .where((category) => widget.isAssembly 
                        ? category == Form1728PCategory.patriotic
                        : category != Form1728PCategory.patriotic)
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        ))
                    .toList(),
                onChanged: (category) => setState(() => _selectedCategory = category),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              SizedBox(height: AppTheme.spacing),

              // Program Dropdown
              DropdownButtonFormField<Form1728PProgram>(
                decoration: AppTheme.formFieldDecorationWithLabel('Program'),
                value: _selectedProgram,
                items: _programs[_selectedCategory]
                    ?.map((program) => DropdownMenuItem(
                          value: program,
                          child: Text(program.name),
                        ))
                    .toList() ?? [],
                onChanged: (program) => setState(() => _selectedProgram = program),
                validator: (value) => value == null ? 'Please select a program' : null,
              ),
              SizedBox(height: AppTheme.spacing),

              // Date
              TextFormField(
                controller: _dateController,
                decoration: AppTheme.formFieldDecorationWithLabel('Date'),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) => value?.isEmpty ?? true ? 'Please select a date' : null,
              ),
              SizedBox(height: AppTheme.spacing),

              // Hours
              TextFormField(
                controller: _hoursController,
                decoration: AppTheme.formFieldDecorationWithLabel('Service Hours'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter hours';
                  if (int.tryParse(value!) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: AppTheme.spacing),

              // Disbursement
              TextFormField(
                controller: _disbursementController,
                decoration: AppTheme.formFieldDecorationWithLabel('Charitable Disbursements'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter disbursement amount';
                  if (double.tryParse(value!) == null) return 'Please enter a valid amount';
                  return null;
                },
              ),
              SizedBox(height: AppTheme.spacing),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: AppTheme.formFieldDecorationWithLabel('Description'),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              SizedBox(height: AppTheme.largeSpacing),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: AppTheme.spacing),
                  FilledButton(
                    style: AppTheme.baseButtonStyle,
                    onPressed: _isLoading ? null : _updateEntry,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 