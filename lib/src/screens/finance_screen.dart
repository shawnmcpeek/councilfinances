import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
      ),
      body: Center(
        child: Text(
          'Finance',
          style: AppTheme.headingStyle,
        ),
      ),
    );
  }
} 