import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/reimbursement_request.dart';
import '../models/program.dart';
import '../services/reimbursement_service.dart';
import '../services/program_service.dart';
import '../providers/organization_provider.dart';
import '../providers/user_provider.dart';
import '../components/organization_toggle.dart';
import '../theme/app_theme.dart';

class ReimbursementRequestScreen extends StatefulWidget {
  const ReimbursementRequestScreen({super.key});

  @override
  State<ReimbursementRequestScreen> createState() => _ReimbursementRequestScreenState();
}

class _ReimbursementRequestScreenState extends State<ReimbursementRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reimbursementService = ReimbursementService();
  final _programService = ProgramService();
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _donationEntityController = TextEditingController();
  final _mailingAddressController = TextEditingController();
  
  // Form state
  String? _selectedProgramId;
  String? _selectedProgramName;
  String _recipientType = 'self';
  String _deliveryMethod = 'meeting';
  final List<String> _documentUrls = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Program> _availablePrograms = [];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _prefillUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _donationEntityController.dispose();
    _mailingAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = context.read<UserProvider>().userProfile;
      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      final organizationId = userProfile?.getOrganizationId(isAssembly) ?? '';
      
      final programsData = await _programService.loadSystemPrograms();
      await _programService.loadProgramStates(programsData, organizationId);
      final customPrograms = await _programService.getCustomPrograms(organizationId);
      
      final List<Program> enabledPrograms = [];
      final programsMap = isAssembly ? programsData.assemblyPrograms : programsData.councilPrograms;
      for (var categoryPrograms in programsMap.values) {
        enabledPrograms.addAll(categoryPrograms.where((p) => p.isEnabled));
      }
      enabledPrograms.addAll(customPrograms.where((p) => p.isEnabled));
      enabledPrograms.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      setState(() {
        _availablePrograms = enabledPrograms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load programs: $e')),
        );
      }
    }
  }

  void _prefillUserData() {
    final userProfile = context.read<UserProvider>().userProfile;
    if (userProfile != null) {
      _firstNameController.text = userProfile.firstName;
      _lastNameController.text = userProfile.lastName;
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        final fileNames = result.files.map((file) => file.name).toList();
        setState(() {
          _documentUrls.addAll(fileNames);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick documents: $e')),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userProfile = context.read<UserProvider>().userProfile;
      final isAssembly = context.read<OrganizationProvider>().isAssembly;
      final organizationId = userProfile?.getOrganizationId(isAssembly) ?? '';
      
      if (userProfile == null || organizationId.isEmpty) {
        throw Exception('User profile or organization not found');
      }

      final request = ReimbursementRequest(
        id: '${organizationId}_${DateTime.now().millisecondsSinceEpoch}',
        organizationId: organizationId,
        organizationType: isAssembly ? 'assembly' : 'council',
        requesterId: userProfile.uid,
        requesterName: '${_firstNameController.text} ${_lastNameController.text}',
        requesterEmail: _emailController.text,
        requesterPhone: _phoneController.text,
        programId: _selectedProgramId!,
        programName: _selectedProgramName!,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        recipientType: _recipientType,
        donationEntity: _recipientType == 'donation' ? _donationEntityController.text : null,
        deliveryMethod: _deliveryMethod,
        mailingAddress: _deliveryMethod == 'mail' ? _mailingAddressController.text : null,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        documentUrls: _documentUrls,
      );

      await _reimbursementService.createReimbursementRequest(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reimbursement request submitted successfully')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrganizationProvider, UserProvider>(
      builder: (context, organizationProvider, userProvider, child) {
        final userProfile = userProvider.userProfile;
        
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: Text('User profile not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Request Reimbursement'),
          ),
          body: AppTheme.screenContent(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const OrganizationToggle(),
                          const SizedBox(height: AppTheme.spacing),
                          
                          // Personal Information Section
                          Card(
                            child: Padding(
                              padding: AppTheme.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Information',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _firstNameController,
                                          decoration: const InputDecoration(
                                            labelText: 'First Name',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your first name';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _lastNameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Last Name',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your last name';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email Address',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email address';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          
                          // Program and Amount Section
                          Card(
                            child: Padding(
                              padding: AppTheme.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Program and Amount',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedProgramId,
                                    decoration: const InputDecoration(
                                      labelText: 'Program',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _availablePrograms.map((program) {
                                      return DropdownMenuItem(
                                        value: program.id,
                                        child: Text(program.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedProgramId = value;
                                        _selectedProgramName = _availablePrograms
                                            .firstWhere((p) => p.id == value)
                                            .name;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a program';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Description of Expense',
                                      border: OutlineInputBorder(),
                                      hintText: 'Describe what this reimbursement is for...',
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please describe the expense';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _amountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                      border: OutlineInputBorder(),
                                      prefixText: '\$',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the amount';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid amount';
                                      }
                                      if (double.parse(value) <= 0) {
                                        return 'Amount must be greater than 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          
                          // Recipient Section
                          Card(
                            child: Padding(
                              padding: AppTheme.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recipient',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  RadioListTile<String>(
                                    title: const Text('For myself'),
                                    value: 'self',
                                    groupValue: _recipientType,
                                    onChanged: (value) {
                                      setState(() => _recipientType = value!);
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('For donation to other entity'),
                                    value: 'donation',
                                    groupValue: _recipientType,
                                    onChanged: (value) {
                                      setState(() => _recipientType = value!);
                                    },
                                  ),
                                  if (_recipientType == 'donation') ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _donationEntityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Donation Entity',
                                        border: OutlineInputBorder(),
                                        hintText: 'e.g., Special Olympics of Colorado',
                                      ),
                                      validator: (value) {
                                        if (_recipientType == 'donation' && (value == null || value.isEmpty)) {
                                          return 'Please specify the donation entity';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          
                          // Delivery Method Section
                          Card(
                            child: Padding(
                              padding: AppTheme.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Method',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  RadioListTile<String>(
                                    title: const Text('Check at next meeting'),
                                    value: 'meeting',
                                    groupValue: _deliveryMethod,
                                    onChanged: (value) {
                                      setState(() => _deliveryMethod = value!);
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Mail to address'),
                                    value: 'mail',
                                    groupValue: _deliveryMethod,
                                    onChanged: (value) {
                                      setState(() => _deliveryMethod = value!);
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Pay Online'),
                                    value: 'online',
                                    groupValue: _deliveryMethod,
                                    onChanged: (value) {
                                      setState(() => _deliveryMethod = value!);
                                    },
                                  ),
                                  if (_deliveryMethod == 'mail') ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _mailingAddressController,
                                      decoration: const InputDecoration(
                                        labelText: 'Mailing Address',
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter complete mailing address...',
                                      ),
                                      maxLines: 3,
                                      validator: (value) {
                                        if (_deliveryMethod == 'mail' && (value == null || value.isEmpty)) {
                                          return 'Please provide a mailing address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          
                          // Document Upload Section
                          Card(
                            child: Padding(
                              padding: AppTheme.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Documentation',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _pickDocuments,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Upload Documents'),
                                  ),
                                  if (_documentUrls.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Uploaded Documents:',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    ...(_documentUrls.map((url) => ListTile(
                                      leading: const Icon(Icons.attachment),
                                      title: Text(url),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            _documentUrls.remove(url);
                                          });
                                        },
                                      ),
                                    )).toList()),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing * 2),
                          
                          // Submit Button
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submitRequest,
                            child: _isSubmitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 16),
                                      Text('Submitting...'),
                                    ],
                                  )
                                : const Text('Submit Reimbursement Request'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}