import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/finance_entry.dart';
import '../models/program.dart';
import '../models/payment_method.dart';
import '../services/finance_service.dart';
import '../utils/logger.dart';
import 'program_dropdown.dart';
import 'package:provider/provider.dart';
import '../providers/program_provider.dart';

class FinanceEntryEditDialog extends StatefulWidget {
  final FinanceEntry entry;
  final String organizationId;
  final bool isAssembly;
  final bool isExpense;
  final VoidCallback onSuccess;

  const FinanceEntryEditDialog({
    super.key,
    required this.entry,
    required this.organizationId,
    required this.isAssembly,
    required this.isExpense,
    required this.onSuccess,
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
    // Initialize form with existing entry data
    _selectedDate = widget.entry.date;
    _dateController.text = _formatDate(_selectedDate);
    _amountController.text = widget.entry.amount.toString();
    _descriptionController.text = widget.entry.description ?? '';
    _selectedPaymentMethod = PaymentMethod.values.firstWhere(
      (method) => method.toString() == widget.entry.paymentMethod,
      orElse: () => PaymentMethod.cash,
    );
    if (widget.entry.checkNumber != null) {
      _checkNumberController.text = widget.entry.checkNumber!;
    }
    _selectedProgram = Program(
      id: widget.entry.program.id,
      name: widget.entry.program.name,
      category: widget.entry.program.category,
      isSystemDefault: widget.entry.program.isSystemDefault,
      financialType: widget.entry.program.financialType,
      isEnabled: true,
      isAssembly: widget.isAssembly,
    );
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

    setState(() => _isLoading = true);

    try {
      await _financeService.updateFinanceEntry(
        organizationId: widget.organizationId,
        entryId: widget.entry.id,
        isAssembly: widget.isAssembly,
        isExpense: widget.isExpense,
        year: widget.entry.date.year,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
        checkNumber: _selectedPaymentMethod == PaymentMethod.check ? _checkNumberController.text.trim() : null,
      );

      if (mounted) {
        widget.onSuccess();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry updated successfully')),
        );
        Provider.of<ProgramProvider>(context, listen: false).reload();
      }
    } catch (e) {
      AppLogger.error('Error updating entry', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating entry: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit ${widget.isExpense ? 'Expense' : 'Income'} Entry',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.largeSpacing),
              ProgramDropdown(
                organizationId: widget.organizationId,
                isAssembly: widget.isAssembly,
                filterType: widget.isExpense ? FinancialType.expenseOnly : FinancialType.incomeOnly,
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
                decoration: AppTheme.formFieldDecorationWithLabel('Payment Method', 'Select payment method'),
                value: _selectedPaymentMethod,
                items: PaymentMethod.values.map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentMethod = value;
                      if (value != PaymentMethod.check) {
                        _checkNumberController.clear();
                      }
                    });
                  }
                },
                validator: (value) => value == null ? 'Please select a payment method' : null,
              ),
              if (_selectedPaymentMethod == PaymentMethod.check) ...[
                SizedBox(height: AppTheme.spacing),
                TextFormField(
                  controller: _checkNumberController,
                  decoration: AppTheme.formFieldDecorationWithLabel('Check Number'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter the check number' : null,
                ),
              ],
              SizedBox(height: AppTheme.spacing),
              TextFormField(
                controller: _descriptionController,
                decoration: AppTheme.formFieldDecorationWithLabel('Description/Notes (Optional)'),
                maxLines: 3,
              ),
              SizedBox(height: AppTheme.largeSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: AppTheme.spacing),
                  FilledButton(
                    style: AppTheme.baseButtonStyle,
                    onPressed: _isLoading ? null : _updateEntry,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 