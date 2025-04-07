import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/program.dart';
import '../models/hours_entry.dart';
import '../models/user_profile.dart';
import '../services/hours_service.dart';
import '../services/program_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../components/program_dropdown.dart';
import '../components/organization_toggle.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../components/hours_entry.dart';
import '../components/hours_history.dart';

class HoursEntryScreen extends StatefulWidget {
  const HoursEntryScreen({Key? key}) : super(key: key);

  @override
  State<HoursEntryScreen> createState() => _HoursEntryScreenState();
}

class _HoursEntryScreenState extends State<HoursEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursService = HoursService();
  final _programService = ProgramService();
  final _userService = UserService();
  
  bool _isLoading = false;
  UserProfile? _userProfile;
  ProgramsData? _systemPrograms;
  List<Program>? _customPrograms;
  Program? _selectedProgram;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();
  final bool _viewingEntries = false;
  List<HoursEntry>? _entries;
  bool _isViewingLogs = false;
  Map<int, List<HoursEntry>> _entriesByYear = {};
  StreamSubscription<List<HoursEntry>>? _entriesSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
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
      
      // Load program states and custom programs
      await _programService.loadProgramStates(_systemPrograms!, _userProfile!.getOrganizationId(true), true);
      final customPrograms = await _programService.getCustomPrograms(_userProfile!.getOrganizationId(true), true);

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
    final List<Program> enabledPrograms = [];
    
    // Add system programs
    final programs = _userProfile!.isAssembly
        ? _systemPrograms?.assemblyPrograms ?? {}
        : _systemPrograms?.councilPrograms ?? {};
    
    for (var categoryPrograms in programs.values) {
      enabledPrograms.addAll(
        categoryPrograms.where((program) => program.isEnabled)
      );
    }
    
    // Add custom programs
    if (_customPrograms != null) {
      enabledPrograms.addAll(
        _customPrograms!.where((program) => program.isEnabled)
      );
    }
    
    return enabledPrograms;
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
        organizationId: _userProfile!.getOrganizationId(true),
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
        startTime: Timestamp.fromDate(startDateTime),
        endTime: Timestamp.fromDate(endDateTime),
        totalHours: _calculateTotalHours(),
        createdAt: DateTime.now(),
      );

      await _hoursService.addHoursEntry(entry, Provider.of<OrganizationProvider>(context, listen: false).isAssembly);
      
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

  void _subscribeToEntries() {
    if (_userProfile == null) return;
    
    _entriesSubscription?.cancel();
    _entriesSubscription = _hoursService
        .getHoursEntries(
          _userProfile!.getOrganizationId(Provider.of<OrganizationProvider>(context, listen: false).isAssembly),
          Provider.of<OrganizationProvider>(context, listen: false).isAssembly
        )
        .listen((entries) {
          if (mounted) {
            setState(() {
              _entriesByYear = {};
              for (var entry in entries) {
                final year = entry.startTime.toDate().year;
                _entriesByYear[year] = [...(_entriesByYear[year] ?? []), entry];
              }
              // Sort entries within each year
              _entriesByYear.forEach((year, entries) {
                entries.sort((a, b) => b.startTime.compareTo(a.startTime));
              });
            });
          }
        }, onError: (e) {
          AppLogger.error('Error loading hours entries', e);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        final organizationId = _userProfile?.getOrganizationId(
          organizationProvider.isAssembly,
        ) ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hours Entry'),
          ),
          body: AppTheme.screenContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OrganizationToggle(),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (organizationId.isEmpty)
                  const Center(child: Text('Please select an organization'))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          HoursEntryForm(
                            organizationId: organizationId,
                            isAssembly: organizationProvider.isAssembly,
                          ),
                          SizedBox(height: AppTheme.spacing),
                          HoursHistoryList(
                            organizationId: organizationId,
                            isAssembly: organizationProvider.isAssembly,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Show Previous Entries'),
        const SizedBox(width: 8),
        Switch(
          value: _isViewingLogs,
          onChanged: (value) {
            setState(() {
              _isViewingLogs = value;
            });
            if (value && _userProfile != null) {
              _subscribeToEntries();
            } else {
              _entriesSubscription?.cancel();
            }
          },
        ),
      ],
    );
  }

  Widget _buildLogsView() {
    final years = _entriesByYear.keys.toList()..sort((a, b) => b.compareTo(a));
    
    if (years.isEmpty) {
      return const Center(
        child: Text('No hours logged yet'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final entries = _entriesByYear[year] ?? [];
        final isCurrentYear = year == 2025;

        return ExpansionTile(
          title: Text('$year'),
          initiallyExpanded: isCurrentYear,
          children: entries.map((entry) => ListTile(
            title: Text(entry.programName),
            subtitle: Text(
              '${_formatDateTime(entry.startTime.toDate())} - ${_formatDateTime(entry.endTime.toDate())}\n'
              '${entry.totalHours} hours'
            ),
          )).toList(),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
} 