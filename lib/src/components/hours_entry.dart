import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/hours_service.dart';
import '../services/program_service.dart';
import '../services/user_service.dart';
import '../models/program.dart';
import '../models/hours_entry.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';

import 'program_dropdown.dart';

class HoursEntryForm extends StatefulWidget {
  final String organizationId;

  const HoursEntryForm({
    super.key,
    required this.organizationId,
  });

  @override
  State<HoursEntryForm> createState() => _HoursEntryFormState();
}

class _HoursEntryFormState extends State<HoursEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _hoursService = HoursService();
  final _programService = ProgramService();
  final _userService = UserService();
  final _disbursementController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  UserProfile? _userProfile;
  ProgramsData? _systemPrograms;
  Program? _selectedProgram;
  HoursCategory? _selectedCategory;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _disbursementController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
      _loadPrograms();
    } catch (e) {
      AppLogger.error('Error loading user profile', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadPrograms() async {
    if (_userProfile == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Load system programs if we haven't yet
      _systemPrograms ??= await _programService.loadSystemPrograms();
      
      // Load program states
      await _programService.loadProgramStates(_systemPrograms!, widget.organizationId);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error loading programs', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _saveEntry() async {
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
      
      final entry = HoursEntry(
        id: '',  // Will be set by Supabase
        userId: '',  // Will be set by service
        organizationId: widget.organizationId,
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
        category: _selectedCategory!,
        startTime: startDateTime,
        endTime: endDateTime,
        totalHours: _calculateTotalHours(),
        disbursement: double.tryParse(_disbursementController.text),
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _hoursService.addHoursEntry(entry);
      
      if (mounted) {
        // Reset form
        setState(() {
          _selectedProgram = null;
          _selectedCategory = null;
          _startDate = DateTime.now();
          _startTime = TimeOfDay.now();
          _endDate = DateTime.now();
          _endTime = TimeOfDay.now();
          _disbursementController.clear();
          _descriptionController.clear();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hours logged successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error saving hours entry', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hours Entry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: AppTheme.spacing),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Category Dropdown
                DropdownButtonFormField<HoursCategory>(
                  decoration: AppTheme.formFieldDecorationWithLabel('Category'),
                  value: _selectedCategory,
                  items: HoursCategory.values
                      .where((category) => !category.isAssemblyOnly || false) // Always show assembly categories
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
                  selectedProgram: _selectedProgram,
                  onChanged: (program) => setState(() => _selectedProgram = program),
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

                // Disbursement Field
                TextFormField(
                  controller: _disbursementController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Charitable Disbursement (Optional)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
                SizedBox(height: AppTheme.spacing),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Description (Optional)'),
                  maxLines: 3,
                ),
                SizedBox(height: AppTheme.spacing),

                // Submit Button
                FilledButton(
                  style: AppTheme.baseButtonStyle,
                  onPressed: _isLoading ? null : _saveEntry,
                  child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Log Hours'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 