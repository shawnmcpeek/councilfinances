import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../reports/audit_field_map.dart';

class AuditManualEntry extends StatefulWidget {
  final Map<String, String> initialValues;
  final Function(Map<String, String>) onValuesChanged;

  const AuditManualEntry({
    super.key,
    required this.initialValues,
    required this.onValuesChanged,
  });

  @override
  State<AuditManualEntry> createState() => _AuditManualEntryState();
}

class _AuditManualEntryState extends State<AuditManualEntry> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _currentValues = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final field in AuditFieldMap.manualEntryFields) {
      final initialValue = widget.initialValues[field] ?? '';
      _controllers[field] = TextEditingController(text: initialValue);
      _currentValues[field] = initialValue;
      
      // Add listener to detect changes
      _controllers[field]!.addListener(() {
        final newValue = _controllers[field]!.text;
        if (_currentValues[field] != newValue) {
          _currentValues[field] = newValue;
          widget.onValuesChanged(_currentValues);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Entry Fields',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Enter values for fields that require manual input',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Income',
              ['Text50', 'Text59'],
              'Enter income values',
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Expenses',
              ['Text69', 'Text70'],
              'Enter expense values',
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Membership',
              ['Text74', 'Text75', 'Text76', 'Text77', 'Text78'],
              'Enter membership values',
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Disbursements',
              ['Text84', 'Text85', 'Text86', 'Text87'],
              'Enter disbursement values',
            ),
            const SizedBox(height: AppTheme.spacing),
            _buildSection(
              'Additional Fields',
              [
                'Text89', 'Text90', 'Text91', 'Text92', 'Text93',
                'Text95', 'Text96', 'Text97', 'Text98', 'Text99',
                'Text100', 'Text101', 'Text102',
                'Text104', 'Text105', 'Text106', 'Text107', 'Text108',
                'Text109', 'Text110'
              ],
              'Enter additional field values',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> fields, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.smallSpacing),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        ...fields.map((field) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
          child: TextFormField(
            controller: _controllers[field],
            decoration: AppTheme.formFieldDecoration.copyWith(
              labelText: _getFieldLabel(field),
              hintText: 'Enter value',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        )),
      ],
    );
  }

  String _getFieldLabel(String field) {
    // Map field IDs to human-readable labels
    final Map<String, String> labels = {
      'Text50': 'Manual Income 1',
      'Text59': 'Manual Income 2',
      'Text69': 'Manual Expense 1',
      'Text70': 'Manual Expense 2',
      'Text74': 'Manual Membership 1',
      'Text75': 'Manual Membership 2',
      'Text76': 'Manual Membership 3',
      'Text77': 'Membership Count',
      'Text78': 'Membership Dues Total',
      'Text84': 'Manual Disbursement 1',
      'Text85': 'Manual Disbursement 2',
      'Text86': 'Manual Disbursement 3',
      'Text87': 'Manual Disbursement 4',
      'Text89': 'Additional Field 1',
      'Text90': 'Additional Field 2',
      'Text91': 'Additional Field 3',
      'Text92': 'Additional Field 4',
      'Text93': 'Additional Field 5',
      'Text95': 'Additional Field 6',
      'Text96': 'Additional Field 7',
      'Text97': 'Additional Field 8',
      'Text98': 'Additional Field 9',
      'Text99': 'Additional Field 10',
      'Text100': 'Additional Field 11',
      'Text101': 'Additional Field 12',
      'Text102': 'Additional Field 13',
      'Text104': 'Additional Field 14',
      'Text105': 'Additional Field 15',
      'Text106': 'Additional Field 16',
      'Text107': 'Additional Field 17',
      'Text108': 'Additional Field 18',
      'Text109': 'Additional Field 19',
      'Text110': 'Additional Field 20',
    };
    return labels[field] ?? field;
  }
} 