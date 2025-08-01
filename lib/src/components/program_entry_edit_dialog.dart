import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../services/program_entry_service.dart';
import '../models/form1728p_program.dart';
import '../models/program_entry_adapter.dart';

class ProgramEntryEditDialog extends StatefulWidget {
  final ProgramEntry entry;
  final String organizationId;

  const ProgramEntryEditDialog({
    super.key,
    required this.entry,
    required this.organizationId,
  });

  @override
  State<ProgramEntryEditDialog> createState() => _ProgramEntryEditDialogState();
}

class _ProgramEntryEditDialogState extends State<ProgramEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _hoursController = TextEditingController();
  final _disbursementController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _programEntryService = ProgramEntryService();
  
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.entry.date;
    _dateController.text = _formatDate(_selectedDate);
    _hoursController.text = widget.entry.hours.toString();
    _disbursementController.text = widget.entry.disbursement.toString();
    _descriptionController.text = widget.entry.description;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _hoursController.dispose();
    _disbursementController.dispose();
    _descriptionController.dispose();
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
      lastDate: DateTime(2101),
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

    setState(() => _isLoading = true);
    try {
      // For program entries, we need to update the individual entry within the aggregated data
      // This is more complex since program entries are stored as aggregated data
      // For now, we'll show a message that this feature is being developed
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program entry editing is being developed. Please delete and recreate the entry for now.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Error updating program entry', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating entry: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Program Entry'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Program: ${widget.entry.program.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: AppTheme.spacing),
                Text(
                  'Category: ${widget.entry.category.displayName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: AppTheme.spacing),
                TextFormField(
                  controller: _dateController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Date'),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) => value?.isEmpty ?? true ? 'Please select a date' : null,
                ),
                SizedBox(height: AppTheme.spacing),
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
                TextFormField(
                  controller: _descriptionController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Description'),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _updateEntry,
          style: AppTheme.filledButtonStyle,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
} 