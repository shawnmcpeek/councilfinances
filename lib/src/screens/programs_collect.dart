import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import '../models/form1728p_program.dart';
import '../services/program_entry_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../models/program_entry_adapter.dart';
import '../utils/logger.dart';
import '../theme/app_theme.dart';
import '../components/organization_toggle.dart';
import '../components/log_display.dart';
import '../components/program_entry_edit_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../providers/program_provider.dart';

class ProgramsCollectScreen extends StatefulWidget {
  const ProgramsCollectScreen({super.key});

  @override
  State<ProgramsCollectScreen> createState() => _ProgramsCollectScreenState();
}

class _ProgramsCollectScreenState extends State<ProgramsCollectScreen> {
  final _programEntryService = ProgramEntryService();
  final _userService = UserService();
  bool _isLoading = false;
  bool _isSaving = false;
  final Map<Form1728PCategory, List<Form1728PProgram>> _programs = {};
  final _hoursController = TextEditingController();
  final _disbursementController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  UserProfile? _userProfile;
  StreamSubscription<List<ProgramEntry>>? _entriesSubscription;
  List<ProgramEntry> _entries = [];
  
  Form1728PCategory? _selectedCategory;
  Form1728PProgram? _selectedProgram;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('ProgramsCollectScreen: Navigated to Programs screen');
    AppLogger.debug('ProgramsCollectScreen: initState called');
    _dateController.text = '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}';
    _loadData();
  }

  @override
  void dispose() {
    AppLogger.debug('ProgramsCollectScreen: Leaving Programs screen');
    AppLogger.debug('ProgramsCollectScreen: dispose called');
    _hoursController.dispose();
    _disbursementController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _entriesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLogger.debug('ProgramsCollectScreen: didChangeDependencies called');
    
    if (_userProfile != null) {
      final organizationId = _getFormattedOrganizationId();
      AppLogger.debug('Got formatted organization ID: $organizationId');
      
      if (organizationId.isNotEmpty) {
        AppLogger.debug('About to subscribe to entries for organization: $organizationId');
        _subscribeToEntries(organizationId);
      } else {
        AppLogger.error('Organization ID is empty in didChangeDependencies');
      }
    } else {
      AppLogger.debug('UserProfile is null in didChangeDependencies');
    }
  }

  String _getFormattedOrganizationId() {
    if (_userProfile == null) return '';
    final isAssembly = Provider.of<OrganizationProvider>(context, listen: false).isAssembly;
    return _userProfile!.getOrganizationId(isAssembly);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Load user profile
      final userProfile = await _userService.getUserProfile();
      if (!mounted) return;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }
      
      // Load and parse JSON
      final String jsonString = await rootBundle.loadString('assets/data/form1728p_programs.json');
      if (!mounted) return;
      
      final jsonData = json.decode(jsonString);
      
      // Initialize programs by category
      final programsMap = <Form1728PCategory, List<Form1728PProgram>>{};
      for (var category in Form1728PCategory.values) {
        programsMap[category] = (jsonData[category.name] as List)
          .map((program) => Form1728PProgram.fromJson(program))
          .toList();
      }

      if (!mounted) return;

      setState(() {
        _userProfile = userProfile;
        _programs.clear();
        _programs.addAll(programsMap);
        _isLoading = false;
      });

      AppLogger.debug('Loaded Form 1728P programs: $_programs');

      // Subscribe to entries after user profile is loaded
      final organizationId = _getFormattedOrganizationId();
      if (organizationId.isNotEmpty) {
        AppLogger.debug('Subscribing to entries after loading data for organization: $organizationId');
        _subscribeToEntries(organizationId);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading Form 1728P programs', e, stackTrace);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToEntries(String organizationId) {
    _entriesSubscription?.cancel();
    
    if (organizationId.isEmpty) {
      setState(() => _entries = []);
      return;
    }

    AppLogger.debug('Subscribing to entries for organization: $organizationId');

    _entriesSubscription = _programEntryService
        .getProgramEntries(organizationId)
        .listen(
          (entries) {
            AppLogger.debug('Received ${entries.length} entries from Firestore');
            if (mounted) {
              setState(() => _entries = entries);
            }
          },
          onError: (error) {
            AppLogger.error('Error loading program entries', error);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading entries: $error')),
              );
            }
          },
        );
  }

  void _onCategoryChanged(Form1728PCategory? category) {
    setState(() {
      _selectedCategory = category;
      _selectedProgram = null;
      _hoursController.clear();
      _disbursementController.clear();
      _descriptionController.clear();
      _selectedDate = DateTime.now();
    });
  }

  void _onProgramChanged(Form1728PProgram? program) {
    setState(() {
      _selectedProgram = program;
      _hoursController.clear();
      _disbursementController.clear();
      _descriptionController.clear();
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  Future<void> _submitEntry() async {
    if (_selectedCategory == null || _selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and program')),
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

    final organizationId = _getFormattedOrganizationId();
    if (organizationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization ID not found')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _programEntryService.saveProgramEntry(
        organizationId: organizationId,
        category: _selectedCategory!,
        program: _selectedProgram!,
        hours: hours,
        disbursement: disbursement,
        description: description,
        date: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved successfully')),
        );
        
        // Clear form after successful save
        setState(() {
          _selectedCategory = null;
          _selectedProgram = null;
          _hoursController.clear();
          _disbursementController.clear();
          _descriptionController.clear();
          _selectedDate = DateTime.now();
        });

        Provider.of<ProgramProvider>(context, listen: false).reload();
      }
    } catch (e) {
      AppLogger.error('Error saving program entry', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onEdit(ProgramEntryAdapter adapter) {
    showDialog(
      context: context,
      builder: (context) => ProgramEntryEditDialog(
        entry: adapter.entry,
        organizationId: _getFormattedOrganizationId(),
        isAssembly: Provider.of<OrganizationProvider>(context, listen: false).isAssembly,
        onSuccess: () {
          // The dialog will handle closing itself and showing success message
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('ProgramsCollectScreen: build called');
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Program Data Collection'),
          ),
          body: AppTheme.screenContent(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OrganizationToggle(),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<Form1728PCategory>(
                            decoration: AppTheme.formFieldDecorationWithLabel('Category'),
                            value: _selectedCategory,
                            items: Form1728PCategory.values
                              .where((category) => organizationProvider.isAssembly 
                                ? category == Form1728PCategory.patriotic
                                : category != Form1728PCategory.patriotic)
                              .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.displayName),
                              )).toList(),
                            onChanged: _onCategoryChanged,
                          ),
                          SizedBox(height: AppTheme.spacing),
                          if (_selectedCategory != null) ...[
                            DropdownButtonFormField<Form1728PProgram>(
                              decoration: AppTheme.formFieldDecorationWithLabel('Charitable Program'),
                              value: _selectedProgram,
                              items: _programs[_selectedCategory]
                                ?.map((program) => DropdownMenuItem(
                                  value: program,
                                  child: Text(program.name),
                                )).toList() ?? [],
                              onChanged: _onProgramChanged,
                            ),
                            SizedBox(height: AppTheme.spacing),
                          ],
                          TextFormField(
                            controller: _dateController,
                            decoration: AppTheme.formFieldDecorationWithLabel(
                              'Program Date',
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                            readOnly: true,
                          ),
                          SizedBox(height: AppTheme.spacing),
                          TextFormField(
                            controller: _hoursController,
                            decoration: AppTheme.formFieldDecorationWithLabel('Service Hours'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          SizedBox(height: AppTheme.spacing),
                          TextFormField(
                            controller: _disbursementController,
                            decoration: AppTheme.formFieldDecorationWithLabel('Charitable Disbursements'),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacing),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: AppTheme.formFieldDecorationWithLabel('Description'),
                            maxLines: 3,
                          ),
                          SizedBox(height: AppTheme.largeSpacing),
                          FilledButton(
                            style: AppTheme.baseButtonStyle,
                            onPressed: _isSaving ? null : _submitEntry,
                            child: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing),
                  LogDisplay<ProgramEntryAdapter>(
                    entries: _entries.map((entry) => ProgramEntryAdapter(entry, hasEditPermission: true, hasDeletePermission: true)).toList(),
                    emptyMessage: 'No program entries found',
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onEdit: _onEdit,
                    onDelete: (adapter) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Entry'),
                          content: const Text('Are you sure you want to delete this entry?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final organizationId = _getFormattedOrganizationId();
                        if (organizationId.isNotEmpty) {
                          await _programEntryService.deleteProgramEntry(
                            organizationId: organizationId,
                            category: adapter.entry.category,
                            programId: adapter.entry.program.id,
                            year: adapter.entry.date.year.toString(),
                          );
                          _subscribeToEntries(organizationId);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}