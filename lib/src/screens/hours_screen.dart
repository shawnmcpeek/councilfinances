import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HoursScreen extends StatelessWidget {
  const HoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Hours'),
      ),
      body: Center(
        child: Text(
          'Volunteer Hours',
          style: AppTheme.headingStyle,
        ),
      ),
    );
  }
} 