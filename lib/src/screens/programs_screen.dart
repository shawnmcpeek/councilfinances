import 'package:flutter/material.dart';
import '../models/program.dart';
import '../models/member_roles.dart';
import '../models/user_profile.dart';
import '../services/program_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';

class ProgramsScreen extends StatefulWidget {
  final String organizationId;

  ProgramsScreen({
    Key? key,
    required this.organizationId,
  }) : super(key: key);

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final ProgramService _programService = ProgramService();
  final UserService _userService = UserService();
  ProgramsData? _systemPrograms;
  List<Program>? _customPrograms;
  bool _isLoading = true;
  String? _organizationId;
  UserProfile? _userProfile;
  bool _hasFullAccess = false;
  bool _hasUnsavedChanges = false;
  final Map<String, bool> _pendingStateChanges = {};

  @override
  void initState() {
    super.initState();
    _organizationId = widget.organizationId;
    _loadPrograms();
  }

  @override
  void didUpdateWidget(ProgramsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      setState(() {
        _organizationId = widget.organizationId;
      });
      // Only reload if we haven't loaded these programs before
      if (_systemPrograms == null) {
        _loadPrograms();
      }
    }
  }

  bool _checkFullAccess() {
    if (_userProfile == null) return false;
    
    final isAssembly = context.read<OrganizationProvider>().isAssembly;
    if (isAssembly) {
      return _userProfile!.assemblyRoles.any((role) => role.accessLevel == AccessLevel.full);
    } else {
      return _userProfile!.councilRoles.any((role) => role.accessLevel == AccessLevel.full);
    }
  }

  Future<void> _loadPrograms() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      if (_organizationId == null || _organizationId!.isEmpty) {
        throw Exception('Invalid organization ID');
      }

      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      AppLogger.debug('Loading programs for organization: $_organizationId, isAssembly: $isAssembly');
      
      // Load system programs only if we haven't loaded them yet
      if (_systemPrograms == null) {
        _systemPrograms = await _programService.loadSystemPrograms();
      }
      
      // Always load the current organization's program states and custom programs
      await _programService.loadProgramStates(_systemPrograms!, _organizationId!, isAssembly);
      final customPrograms = await _programService.getCustomPrograms(_organizationId!, isAssembly);

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _customPrograms = customPrograms;
          _hasFullAccess = _checkFullAccess();
          _hasUnsavedChanges = false;
          _pendingStateChanges.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading programs', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading programs: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleOrganizationType() {
    if (_hasUnsavedChanges) {
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DISCARD'),
            ),
          ],
        ),
      ).then((discard) {
        if (discard == true) {
          final organizationProvider = context.read<OrganizationProvider>();
          organizationProvider.toggleOrganization();
          setState(() {
            _hasFullAccess = _checkFullAccess();
            _hasUnsavedChanges = false;
            _pendingStateChanges.clear();
          });
          _loadPrograms();
        }
      });
    } else {
      final organizationProvider = context.read<OrganizationProvider>();
      organizationProvider.toggleOrganization();
      setState(() {
        _hasFullAccess = _checkFullAccess();
      });
      _loadPrograms();
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasUnsavedChanges) return;

    setState(() => _isLoading = true);
    try {
      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      // Get all programs (both system and custom)
      final programs = isAssembly 
          ? _systemPrograms?.assemblyPrograms ?? {}
          : _systemPrograms?.councilPrograms ?? {};

      // Create a map of all program states
      final Map<String, bool> allProgramStates = {};
      
      AppLogger.debug('Collecting program states...');
      // Add system program states
      for (var categoryPrograms in programs.values) {
        for (var program in categoryPrograms) {
          // Use pending state if exists, otherwise use current state
          final bool isEnabled = _pendingStateChanges.containsKey(program.id)
              ? _pendingStateChanges[program.id]!
              : program.isEnabled;
          allProgramStates[program.id] = isEnabled;
          AppLogger.debug('Program ${program.name} (${program.id}): $isEnabled');
        }
      }

      // Add custom program states if they exist
      if (_customPrograms != null) {
        for (var program in _customPrograms!) {
          final bool isEnabled = _pendingStateChanges.containsKey(program.id)
              ? _pendingStateChanges[program.id]!
              : program.isEnabled;
          allProgramStates[program.id] = isEnabled;
          AppLogger.debug('Custom program ${program.name} (${program.id}): $isEnabled');
        }
      }

      AppLogger.debug('Saving program states to Firestore: $allProgramStates');
      // Save all states at once
      await _programService.updateProgramStates(_organizationId!, allProgramStates);

      setState(() {
        _hasUnsavedChanges = false;
        _pendingStateChanges.clear();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error saving changes', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleProgramStatus(Program program) {
    if (!_hasFullAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to modify programs')),
      );
      return;
    }

    setState(() {
      _pendingStateChanges[program.id] = !program.isEnabled;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _addCustomProgram() async {
    if (!_hasFullAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to add programs')),
      );
      return;
    }

    final isAssembly = context.read<OrganizationProvider>().isAssembly;
    final result = await showDialog<Program>(
      context: context,
      builder: (context) => _ProgramDialog(
        isAssembly: isAssembly,
      ),
    );

    if (result != null && _organizationId != null) {
      try {
        await _programService.addCustomProgram(_organizationId!, result, isAssembly);
        _loadPrograms();
      } catch (e) {
        AppLogger.error('Error adding program', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding program: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAssembly = context.watch<OrganizationProvider>().isAssembly;
    return Scaffold(
      appBar: AppBar(
        title: Text('${isAssembly ? 'Assembly' : 'Council'} Programs'),
        actions: [
          if (_hasUnsavedChanges && _hasFullAccess)
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _hasFullAccess ? FloatingActionButton(
        onPressed: _addCustomProgram,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAssembly = context.watch<OrganizationProvider>().isAssembly;
    final systemPrograms = isAssembly 
        ? _systemPrograms?.assemblyPrograms ?? {}
        : _systemPrograms?.councilPrograms ?? {};

    // Merge custom programs into their categories
    final Map<String, List<Program>> mergedPrograms = {};
    
    // Initialize with system programs
    for (var entry in systemPrograms.entries) {
      mergedPrograms[entry.key.toLowerCase()] = List.from(entry.value);
    }
    
    // Add custom programs to their respective categories
    if (_customPrograms != null) {
      for (var program in _customPrograms!) {
        final category = program.category.toLowerCase();
        mergedPrograms.putIfAbsent(category, () => []);
        mergedPrograms[category]!.add(program);
      }
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppTheme.spacing),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: FilledButton(
                  onPressed: () {
                    if (isAssembly) return;
                    if (_userProfile?.councilNumber == null) return;
                    setState(() {
                      _hasFullAccess = _checkFullAccess();
                      _hasUnsavedChanges = false;
                      _pendingStateChanges.clear();
                      _organizationId = 'C${_userProfile!.councilNumber.toString().padLeft(6, '0')}';
                    });
                    _loadPrograms();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: !isAssembly 
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.1),
                    foregroundColor: !isAssembly
                      ? Colors.white
                      : AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'Council #${_userProfile?.councilNumber ?? ""}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_userProfile?.assemblyNumber != null) ...[
                SizedBox(width: AppTheme.spacing),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    onPressed: () {
                      if (!isAssembly) return;
                      if (_userProfile?.assemblyNumber == null) return;
                      setState(() {
                        _hasFullAccess = _checkFullAccess();
                        _hasUnsavedChanges = false;
                        _pendingStateChanges.clear();
                        _organizationId = 'A${_userProfile!.assemblyNumber.toString().padLeft(6, '0')}';
                      });
                      _loadPrograms();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isAssembly 
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.1),
                      foregroundColor: isAssembly
                        ? Colors.white
                        : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text(
                      'Assembly #${_userProfile?.assemblyNumber ?? ""}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (mergedPrograms.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                isAssembly ? 'No assembly programs available' : 'No council programs available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppTheme.spacing),
              children: mergedPrograms.entries.map((entry) => _buildCategorySection(
                entry.key,
                entry.value,
                false,
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<Program> programs, bool isSystem) {
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacing),
      child: ExpansionTile(
        title: Text(category.toUpperCase(), style: AppTheme.subheadingStyle),
        children: programs.map((program) => _buildProgramTile(program)).toList(),
      ),
    );
  }

  Widget _buildProgramTile(Program program) {
    // Get the current enabled state, considering pending changes
    final bool isEnabled = _pendingStateChanges.containsKey(program.id)
        ? _pendingStateChanges[program.id]!
        : program.isEnabled;

    return ListTile(
      title: Text(program.name),
      trailing: _hasFullAccess ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: isEnabled,
            onChanged: (value) => _toggleProgramStatus(program),
          ),
          if (!program.isSystemDefault) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final isAssembly = context.read<OrganizationProvider>().isAssembly;
                final result = await showDialog<Program>(
                  context: context,
                  builder: (context) => _ProgramDialog(
                    isAssembly: isAssembly,
                    program: program,
                  ),
                );

                if (result != null && _organizationId != null) {
                  try {
                    await _programService.updateCustomProgram(_organizationId!, result, isAssembly);
                    _loadPrograms();
                  } catch (e) {
                    AppLogger.error('Error updating program', e);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating program: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Program'),
                    content: const Text('Are you sure you want to delete this program?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && _organizationId != null) {
                  try {
                    final isAssembly = context.read<OrganizationProvider>().isAssembly;
                    await _programService.deleteCustomProgram(_organizationId!, program.id, isAssembly);
                    _loadPrograms();
                  } catch (e) {
                    AppLogger.error('Error deleting program', e);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting program: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ],
      ) : null,
    );
  }
}

class _ProgramDialog extends StatefulWidget {
  final bool isAssembly;
  final Program? program;

  const _ProgramDialog({
    required this.isAssembly,
    this.program,
  });

  @override
  State<_ProgramDialog> createState() => _ProgramDialogState();
}

class _ProgramDialogState extends State<_ProgramDialog> {
  late final TextEditingController _nameController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _selectedCategory = widget.program?.category ?? 
        (widget.isAssembly ? 'PATRIOTIC' : 'FAITH');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.isAssembly 
        ? [ProgramCategory.patriotic]
        : [
            ProgramCategory.faith,
            ProgramCategory.family,
            ProgramCategory.community,
            ProgramCategory.life,
          ];

    return AlertDialog(
      title: Text(widget.program == null ? 'Add Program' : 'Edit Program'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Program Name',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: categories.map((category) => DropdownMenuItem(
              value: category.toString().split('.').last,
              child: Text(category.toString().split('.').last),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) {
              return;
            }

            final program = Program(
              id: widget.program?.id ?? '',
              name: _nameController.text,
              category: _selectedCategory,
              isSystemDefault: false,
            );

            Navigator.pop(context, program);
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
} 