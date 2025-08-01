import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../services/finance_service.dart';
import '../models/finance_entry.dart';
import '../models/program.dart';
import '../models/payment_method.dart';
import 'program_dropdown.dart';

class FinanceEntryEditDialog extends StatefulWidget {
  final FinanceEntry entry;
  final String organizationId;

  const FinanceEntryEditDialog({
    super.key,
    required this.entry,
    required this.organizationId,
  });

  @override
  State<FinanceEntryEditDialog> createState() => _FinanceEntryEditDialogState();
}

class _FinanceEntryEditDialogState extends State<FinanceEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _financeService = FinanceService();
  
  bool _isLoading = false;
  Program? _selectedProgram;
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _selectedProgram = widget.entry.program;
    _selectedDate = widget.entry.date;
    _amountController.text = widget.entry.amount.toString();
    _descriptionController.text = widget.entry.description ?? '';
    _checkNumberController.text = widget.entry.checkNumber ?? '';
    _dateController.text = _formatDate(_selectedDate);
    
    // Set payment method
    if (widget.entry.paymentMethod != null) {
      _selectedPaymentMethod = PaymentMethod.values.firstWhere(
        (method) => method.displayName == widget.entry.paymentMethod,
        orElse: () => PaymentMethod.cash,
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _checkNumberController.dispose();
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
    if (_selectedProgram == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedEntry = FinanceEntry(
        id: widget.entry.id,
        date: _selectedDate,
        program: _selectedProgram!,
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedPaymentMethod.displayName,
        checkNumber: _checkNumberController.text.trim().isEmpty ? null : _checkNumberController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isExpense: widget.entry.isExpense,
      );

      await _financeService.updateFinanceEntry(
        organizationId: widget.organizationId,
        entry: updatedEntry,
      );
      
      if (mounted) {
        Navigator.of(context).pop(updatedEntry);
      }
    } catch (e) {
      AppLogger.error('Error updating finance entry', e);
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
      title: Text('Edit ${widget.entry.isExpense ? 'Expense' : 'Income'} Entry'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgramDropdown(
                  organizationId: widget.organizationId,
                  filterType: widget.entry.isExpense ? FinancialType.expenseOnly : FinancialType.incomeOnly,
                  selectedProgram: _selectedProgram,
                  onChanged: (value) => setState(() => _selectedProgram = value),
                  validator: (value) => value == null ? 'Please select a program' : null,
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
                  controller: _amountController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter an amount';
                    if (double.tryParse(value!) == null) return 'Please enter a valid amount';
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacing),
                DropdownButtonFormField<PaymentMethod>(
                  value: _selectedPaymentMethod,
                  decoration: AppTheme.formFieldDecorationWithLabel('Payment Method'),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPaymentMethod = value);
                    }
                  },
                ),
                SizedBox(height: AppTheme.spacing),
                TextFormField(
                  controller: _checkNumberController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Check Number (Optional)'),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: AppTheme.spacing),
                TextFormField(
                  controller: _descriptionController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Description (Optional)'),
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