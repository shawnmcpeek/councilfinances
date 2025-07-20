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

  const ProgramsScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final _userService = UserService();
  final _programService = ProgramService();
  String? _organizationId;
  UserProfile? _userProfile;
  ProgramsData? _systemPrograms;
  List<Program> _customPrograms = [];
  bool _hasFullAccess = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  final Map<String, bool> _pendingStateChanges = {};

  @override
  void initState() {
    super.initState();
    _organizationId = widget.organizationId;
    _userService.getUserProfile().then((profile) {
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });
    _loadPrograms();
      }
    });
  }

  @override
  void didUpdateWidget(ProgramsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      setState(() {
        _organizationId = widget.organizationId;
      });
      // Only reload if we haven't loaded these programs before
      if (_systemPrograms == null && _userProfile != null) {
        _loadPrograms();
      }
    }
  }

  bool _checkFullAccess() {
    if (_userProfile == null) {
      AppLogger.debug('_checkFullAccess: _userProfile is null');
      return false;
    }
    
    final isAssembly = context.read<OrganizationProvider>().isAssembly;
    AppLogger.debug('_checkFullAccess: isAssembly=$isAssembly, councilRoles=${_userProfile!.councilRoles}, assemblyRoles=${_userProfile!.assemblyRoles}');
    
    if (isAssembly) {
      final hasFullAccess = _userProfile!.assemblyRoles.any((role) => role.accessLevel == AccessLevel.full);
      AppLogger.debug('_checkFullAccess: Assembly mode, hasFullAccess=$hasFullAccess');
      return hasFullAccess;
    } else {
      final hasFullAccess = _userProfile!.councilRoles.any((role) => role.accessLevel == AccessLevel.full);
      AppLogger.debug('_checkFullAccess: Council mode, hasFullAccess=$hasFullAccess');
      return hasFullAccess;
    }
  }

  Future<void> _loadPrograms() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final userProfile = await _userService.getUserProfile();
      if (!mounted) return;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final orgId = _organizationId ?? '';
      if (orgId.isEmpty) {
        throw Exception('Invalid organization ID');
      }

      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      AppLogger.debug('Loading programs for organization: $orgId, isAssembly: $isAssembly');
      
      // Load system programs only if we haven't loaded them yet
      _systemPrograms ??= await _programService.loadSystemPrograms();
      
      // Always load the current organization's program states and custom programs
      await _programService.loadProgramStates(_systemPrograms!, orgId, isAssembly);

      // Determine correct orgId and isAssembly for custom programs
      String customOrgId = orgId;
      bool customIsAssembly = isAssembly;
      if (!isAssembly && orgId.startsWith('A')) {
        // If in council mode but orgId is assembly, switch to council orgId
        if (_userProfile?.councilNumber != null) {
          customOrgId = 'C${_userProfile!.councilNumber.toString().padLeft(6, '0')}';
          customIsAssembly = false;
        }
      }
      AppLogger.debug('getCustomPrograms called with orgId: $customOrgId, isAssembly: $customIsAssembly');
      final customPrograms = await _programService.getCustomPrograms(customOrgId, customIsAssembly);

      if (!mounted) return;
      setState(() {
        _userProfile = userProfile;
        _customPrograms = customPrograms;
        AppLogger.debug('Loaded custom programs: ${_customPrograms.map((p) => p.name).toList()}');
        _hasFullAccess = _checkFullAccess();
        _hasUnsavedChanges = false;
        _pendingStateChanges.clear();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading programs', e);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading programs: ${e.toString()}')),
      );
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

      // Add custom program states
      for (var program in _customPrograms) {
        final bool isEnabled = _pendingStateChanges.containsKey(program.id)
            ? _pendingStateChanges[program.id]!
            : program.isEnabled;
        allProgramStates[program.id] = isEnabled;
        AppLogger.debug('Custom program ${program.name} (${program.id}): $isEnabled');
      }

              AppLogger.debug('Saving program states to Supabase: $allProgramStates');
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
    AppLogger.debug('_addCustomProgram called, _hasFullAccess=$_hasFullAccess');
    if (!_hasFullAccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to add programs')),
      );
      return;
    }

    final isAssembly = context.read<OrganizationProvider>().isAssembly;
    if (!mounted) return;
    final result = await showDialog<Program>(
      context: context,
      builder: (context) => _ProgramDialog(
        isAssembly: isAssembly,
      ),
    );

    if (result != null && _organizationId != null) {
      try {
        await _programService.addCustomProgram(_organizationId!, result, isAssembly);
        if (!mounted) return;
        _loadPrograms();
      } catch (e) {
        AppLogger.error('Error adding program', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding program: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAssembly = context.watch<OrganizationProvider>().isAssembly;
    AppLogger.debug('ProgramsScreen build: _hasFullAccess=$_hasFullAccess, isAssembly=$isAssembly');

    return Scaffold(
      appBar: AppBar(
        title: Text('${isAssembly ? 'Assembly' : 'Council'} Programs'),
        actions: [
          if (_hasUnsavedChanges && _hasFullAccess)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('SAVE CHANGES'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          if (_hasUnsavedChanges && _hasFullAccess)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing),
              child: FilledButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('SAVE PROGRAM CHANGES'),
                style: AppTheme.filledButtonStyle,
              ),
            ),
        ],
      ),
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
    final programs = isAssembly 
        ? _systemPrograms?.assemblyPrograms ?? {}
        : _systemPrograms?.councilPrograms ?? {};

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
                    AppLogger.debug('Council button pressed. Current isAssembly: $isAssembly');
                    if (_userProfile?.councilNumber == null) {
                      AppLogger.debug('Council number is null, returning');
                      return;
                    }
                    if (!isAssembly) {
                      AppLogger.debug('Already in Council mode, returning');
                      return;
                    }
                    setState(() {
                      _hasFullAccess = _checkFullAccess();
                      _hasUnsavedChanges = false;
                      _pendingStateChanges.clear();
                      _organizationId = 'C${_userProfile!.councilNumber.toString().padLeft(6, '0')}';
                    });
                    context.read<OrganizationProvider>().setOrganization(false);
                    _loadPrograms();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: !isAssembly 
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withAlpha(25),
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
                      AppLogger.debug('Assembly button pressed. Current isAssembly: $isAssembly');
                      if (_userProfile?.assemblyNumber == null) {
                        AppLogger.debug('Assembly number is null, returning');
                        return;
                      }
                      if (isAssembly) {
                        AppLogger.debug('Already in Assembly mode, returning');
                        return;
                      }
                      AppLogger.debug('Switching to Assembly mode. Assembly number: ${_userProfile!.assemblyNumber}');
                      setState(() {
                        _hasFullAccess = _checkFullAccess();
                        _hasUnsavedChanges = false;
                        _pendingStateChanges.clear();
                        _organizationId = 'A${_userProfile!.assemblyNumber.toString().padLeft(6, '0')}';
                      });
                      context.read<OrganizationProvider>().setOrganization(true);
                      _loadPrograms();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isAssembly 
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withAlpha(25),
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
        if (programs.isEmpty && _customPrograms.isEmpty)
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
            child: Material(
              child: ListView(
                padding: EdgeInsets.all(AppTheme.spacing),
                children: [
                  // System and custom programs by category
                  for (var entry in programs.entries) ...[
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key[0].toUpperCase() + entry.key.substring(1).toLowerCase(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: AppTheme.spacing),
                            // Combine system and custom programs for this category
                            ...[
                              ...entry.value,
                              ..._customPrograms.where((p) => p.category.toLowerCase() == entry.key.toLowerCase())
                            ].map((program) => _buildProgramTile(program)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgramTile(Program program) {
    // Get the current enabled state, considering pending changes
    final bool isEnabled = _pendingStateChanges.containsKey(program.id)
        ? _pendingStateChanges[program.id] ?? program.isEnabled
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
                if (!mounted) return;
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
                    if (!mounted) return;
                    _loadPrograms();
                  } catch (e) {
                    AppLogger.error('Error updating program', e);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating program: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (!mounted) return;
                final isAssembly = context.read<OrganizationProvider>().isAssembly;
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
                    await _programService.deleteCustomProgram(_organizationId!, program.id, isAssembly);
                    if (!mounted) return;
                    _loadPrograms();
                  } catch (e) {
                    AppLogger.error('Error deleting program', e);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting program: ${e.toString()}')),
                    );
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
        (widget.isAssembly ? ProgramCategory.patriotic.name : ProgramCategory.faith.name);
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
              value: category.name,
              child: Text(
                category.name[0].toUpperCase() + category.name.substring(1).toLowerCase(),
              ),
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