import 'package:flutter/material.dart';
import '../components/budget_entry_table.dart';
import '../models/user_profile.dart';

class BudgetEntryScreen extends StatelessWidget {
  final String organizationId;
  final UserProfile userProfile;
  final String year;
  final bool isFullAccess;

  const BudgetEntryScreen({
    super.key,
    required this.organizationId,
    required this.userProfile,
    required this.year,
    required this.isFullAccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Annual Budget for $year'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BudgetEntryTable(
            organizationId: organizationId,
            userProfile: userProfile,
            year: year,
            isFullAccess: isFullAccess,
          ),
        ),
      ),
    );
  }
} 