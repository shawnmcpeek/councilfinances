import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/form1728p_program.dart';
import '../services/program_entry_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';
import '../theme/app_theme.dart';
import '../components/organization_toggle.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';

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
  DateTime _selectedDate = DateTime.now();
  UserProfile? _userProfile;
  
  Form1728PCategory? _selectedCategory;
  Form1728PProgram? _selectedProgram;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('ProgramsCollectScreen: initState called');
    _loadData();
  }

  @override
  void dispose() {
    AppLogger.debug('ProgramsCollectScreen: dispose called');
    _hoursController.dispose();
    _disbursementController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load user profile
      final userProfile = await _userService.getUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found');
      }
      
      // Load and parse the JSON file
      final String jsonString = await rootBundle.loadString('assets/data/form1728p_programs.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Initialize programs by category
      for (var category in Form1728PCategory.values) {
        final categoryPrograms = (jsonData[category.name] as List)
          .map((program) => Form1728PProgram.fromJson(program))
          .toList();
        _programs[category] = categoryPrograms;
      }

      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });

      AppLogger.debug('Loaded Form 1728P programs: $_programs');
    } catch (e, stackTrace) {
      AppLogger.error('Error loading Form 1728P programs', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFormattedOrganizationId() {
    if (_userProfile == null) return '';
    return _userProfile!.getOrganizationId(
      Provider.of<OrganizationProvider>(context, listen: false).isAssembly
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
                  SizedBox(height: AppTheme.spacing),
                  DropdownButtonFormField<Form1728PCategory>(
                    decoration: AppTheme.formFieldDecorationWithLabel('Category'),
                    value: _selectedCategory,
                    items: Form1728PCategory.values.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    )).toList(),
                    onChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: 24),

                  // Program Dropdown
                  DropdownButtonFormField<Form1728PProgram>(
                    decoration: AppTheme.formFieldDecorationWithLabel('Charitable Program'),
                    value: _selectedProgram,
                    items: _selectedCategory != null 
                      ? _programs[_selectedCategory]?.map((program) {
                          return DropdownMenuItem(
                            value: program,
                            child: Text(program.name),
                          );
                        }).toList() ?? []
                      : [],
                    onChanged: _onProgramChanged,
                  ),
                  SizedBox(height: AppTheme.spacing),

                  // Date Picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: AppTheme.formFieldDecorationWithLabel('Program Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing),

                  // Hours Input
                  TextField(
                    controller: _hoursController,
                    decoration: AppTheme.formFieldDecorationWithLabel('Service Hours')
                        .copyWith(hintText: 'Enter total volunteer hours'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: AppTheme.spacing),

                  // Disbursement Input
                  TextField(
                    controller: _disbursementController,
                    decoration: AppTheme.formFieldDecorationWithLabel('Charitable Disbursements')
                        .copyWith(
                          hintText: 'Enter total charitable disbursements',
                          prefixText: '\$',
                        ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacing),

                  // Description Input
                  TextField(
                    controller: _descriptionController,
                    decoration: AppTheme.formFieldDecorationWithLabel('Description')
                        .copyWith(hintText: 'Describe the activity (e.g., "March for Life Rally in DC")'),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  SizedBox(height: AppTheme.largeSpacing),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submitEntry,
                    icon: _isSaving 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Submit'),
                    style: AppTheme.filledButtonStyle,
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