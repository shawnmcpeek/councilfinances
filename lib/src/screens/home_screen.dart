import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../theme/app_theme.dart';
import '../components/organization_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
          ),
          body: AppTheme.screenContent(
            child: Column(
              children: [
                const OrganizationToggle(),
                Expanded(
                  child: Center(
                    child: Text(
                      'Welcome to ${organizationProvider.isAssembly ? 'Assembly' : 'Council'} Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 