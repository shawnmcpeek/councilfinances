import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/logger.dart';
import '../../services/finance_service.dart';
import '../../models/program.dart';
import '../../models/payment_method.dart';
import '../../components/program_dropdown.dart';

class ExpenseEntry extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;

  const ExpenseEntry({
    super.key,
    required this.organizationId,
    required this.isAssembly,
  });

  @override
  State<ExpenseEntry> createState() => _ExpenseEntryState();
}

class _ExpenseEntryState extends State<ExpenseEntry> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _financeService = FinanceService();
  
  bool _isExpanded = true;
  Program? _selectedProgram;
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate);
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

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _financeService.addExpenseEntry(
        organizationId: widget.organizationId,
        isAssembly: widget.isAssembly,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
        checkNumber: _selectedPaymentMethod == PaymentMethod.check ? _checkNumberController.text.trim() : null,
      );

      // Clear form after successful submission
      _amountController.clear();
      _descriptionController.clear();
      _selectedProgram = null;
      setState(() {
        _selectedDate = DateTime.now();
        _dateController.text = _formatDate(_selectedDate);
        _selectedPaymentMethod = PaymentMethod.cash;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense entry saved successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error submitting expense entry', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing,
                vertical: _isExpanded ? AppTheme.spacing : AppTheme.smallSpacing,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Expense Entry',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgramDropdown(
                      organizationId: widget.organizationId,
                      isAssembly: widget.isAssembly,
                      filterType: FinancialType.expenseOnly,
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
                      decoration: AppTheme.formFieldDecorationWithLabel('Description/Notes'),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
                    ),
                    SizedBox(height: AppTheme.largeSpacing),
                    FilledButton(
                      style: AppTheme.baseButtonStyle,
                      onPressed: _submitExpense,
                      child: const Text('Submit Expense Entry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 