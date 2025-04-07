import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/logger.dart';
import '../../services/finance_service.dart';
import '../../services/program_service.dart';
import '../../models/program.dart';
import '../../models/payment_method.dart';
import '../../components/program_dropdown.dart';

class IncomeEntry extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;

  const IncomeEntry({
    super.key,
    required this.organizationId,
    required this.isAssembly,
  });

  @override
  State<IncomeEntry> createState() => _IncomeEntryState();
}

class _IncomeEntryState extends State<IncomeEntry> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _financeService = FinanceService();
  final _programService = ProgramService();
  
  bool _isLoading = true;
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

  Future<void> _submitIncome() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _financeService.addIncomeEntry(
        organizationId: widget.organizationId,
        isAssembly: widget.isAssembly,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        programId: _selectedProgram!.id,
        programName: _selectedProgram!.name,
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
          const SnackBar(content: Text('Income entry saved successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error submitting income entry', e);
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
              padding: EdgeInsets.all(AppTheme.spacing),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Income Entry',
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
                      filterType: FinancialType.incomeOnly,
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
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Please select a payment method' : null,
                    ),
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
                      onPressed: _submitIncome,
                      child: const Text('Submit Income Entry'),
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