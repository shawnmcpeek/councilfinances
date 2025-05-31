import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/hours_service.dart';
import '../models/hours_entry.dart';
import '../models/program.dart';
import '../utils/logger.dart';
import 'program_dropdown.dart';
import 'package:provider/provider.dart';
import '../providers/program_provider.dart';

class HoursEntryEditDialog extends StatefulWidget {
  final HoursEntry entry;
  final String organizationId;
  final bool isAssembly;
  final VoidCallback onSuccess;

  const HoursEntryEditDialog({
    super.key,
    required this.entry,
    required this.organizationId,
    required this.isAssembly,
    required this.onSuccess,
  });

  @override
  State<HoursEntryEditDialog> createState() => _HoursEntryEditDialogState();
}

class _HoursEntryEditDialogState extends State<HoursEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoursService = HoursService();
  final _disbursementController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  Program? _selectedProgram;
  HoursCategory? _selectedCategory;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // Initialize form with existing entry data
    _startDate = widget.entry.startTime.toDate();
    _startTime = TimeOfDay.fromDateTime(widget.entry.startTime.toDate());
    _endDate = widget.entry.endTime.toDate();
    _endTime = TimeOfDay.fromDateTime(widget.entry.endTime.toDate());
    _selectedCategory = widget.entry.category;
    if (widget.entry.disbursement != null) {
      _disbursementController.text = widget.entry.disbursement.toString();
    }
    if (widget.entry.description != null) {
      _descriptionController.text = widget.entry.description!;
    }
    _selectedProgram = Program(
      id: widget.entry.programId,
      name: widget.entry.programName,
      category: widget.entry.category.name,
      isSystemDefault: false,
      financialType: FinancialType.both,
      isEnabled: true,
      isAssembly: widget.isAssembly,
    );
  }

  @override
  void dispose() {
    _disbursementController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && mounted) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  double _calculateTotalHours() {
    final start = _combineDateAndTime(_startDate, _startTime);
    final end = _combineDateAndTime(_endDate, _endTime);
    return end.difference(start).inMinutes / 60.0;
  }

  Future<void> _updateEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final startDateTime = _combineDateAndTime(_startDate, _startTime);
      final endDateTime = _combineDateAndTime(_endDate, _endTime);
      
      final updatedEntry = widget.entry.copyWith(
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
        category: _selectedCategory!,
        startTime: Timestamp.fromDate(startDateTime),
        endTime: Timestamp.fromDate(endDateTime),
        totalHours: _calculateTotalHours(),
        disbursement: double.tryParse(_disbursementController.text),
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _hoursService.updateHoursEntry(updatedEntry, widget.isAssembly);
      
      if (mounted) {
        widget.onSuccess();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hours entry updated successfully')),
        );
        Provider.of<ProgramProvider>(context, listen: false).reload();
      }
    } catch (e) {
      AppLogger.error('Error updating hours entry', e);
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
                'Edit Hours Entry',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.largeSpacing),
              
              // Category Dropdown
              DropdownButtonFormField<HoursCategory>(
                decoration: AppTheme.formFieldDecorationWithLabel('Category'),
                value: _selectedCategory,
                items: HoursCategory.values
                    .where((category) => !category.isAssemblyOnly || widget.isAssembly)
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
              ProgramDropdown(
                organizationId: widget.organizationId,
                isAssembly: widget.isAssembly,
                selectedProgram: _selectedProgram,
                onChanged: (program) => setState(() => _selectedProgram = program),
                validator: (value) => value == null ? 'Please select a program' : null,
              ),
              SizedBox(height: AppTheme.spacing),

              // Start Date/Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing),

              // End Date/Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing),

              // Total Hours Display
              Text(
                'Total Hours: ${_calculateTotalHours().toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing),

              // Disbursement
              TextFormField(
                controller: _disbursementController,
                decoration: AppTheme.formFieldDecorationWithLabel('Disbursement (Optional)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              SizedBox(height: AppTheme.spacing),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: AppTheme.formFieldDecorationWithLabel('Description/Notes (Optional)'),
                maxLines: 3,
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