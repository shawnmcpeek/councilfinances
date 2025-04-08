import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/hours_service.dart';
import '../services/program_service.dart';
import '../services/user_service.dart';
import '../models/program.dart';
import '../models/hours_entry.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'program_dropdown.dart';

class HoursEntryForm extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;

  const HoursEntryForm({
    super.key,
    required this.organizationId,
    required this.isAssembly,
  });

  @override
  State<HoursEntryForm> createState() => _HoursEntryFormState();
}

class _HoursEntryFormState extends State<HoursEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _hoursService = HoursService();
  final _programService = ProgramService();
  final _userService = UserService();
  
  bool _isLoading = false;
  UserProfile? _userProfile;
  ProgramsData? _systemPrograms;
  Program? _selectedProgram;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
      await _programService.loadProgramStates(_systemPrograms!, widget.organizationId, widget.isAssembly);

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

    setState(() => _isLoading = true);
    try {
      final startDateTime = _combineDateAndTime(_startDate, _startTime);
      final endDateTime = _combineDateAndTime(_endDate, _endTime);
      
      final entry = HoursEntry(
        id: '',  // Will be set by Firestore
        userId: '',  // Will be set by service
        organizationId: widget.organizationId,
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
        startTime: Timestamp.fromDate(startDateTime),
        endTime: Timestamp.fromDate(endDateTime),
        totalHours: _calculateTotalHours(),
        createdAt: DateTime.now(),
      );

      await _hoursService.addHoursEntry(entry, widget.isAssembly);
      
      if (mounted) {
        // Reset form
        setState(() {
          _selectedProgram = null;
          _startDate = DateTime.now();
          _startTime = TimeOfDay.now();
          _endDate = DateTime.now();
          _endTime = TimeOfDay.now();
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
                // Program Dropdown
                ProgramDropdown(
                  organizationId: widget.organizationId,
                  isAssembly: widget.isAssembly,
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

                // Submit Button
                ElevatedButton(
                  onPressed: _saveEntry,
                  child: const Text('Log Hours'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 