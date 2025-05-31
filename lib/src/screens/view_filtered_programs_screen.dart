import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/program_provider.dart';
import '../models/program.dart';

class ViewFilteredProgramsScreen extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;

  const ViewFilteredProgramsScreen({
    super.key,
    required this.organizationId,
    required this.isAssembly,
  });

  @override
  State<ViewFilteredProgramsScreen> createState() => _ViewFilteredProgramsScreenState();
}

class _ViewFilteredProgramsScreenState extends State<ViewFilteredProgramsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgramProvider>(context, listen: false).loadPrograms(
        organizationId: widget.organizationId,
        isAssembly: widget.isAssembly,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final programProvider = Provider.of<ProgramProvider>(context);
    final programs = programProvider.activePrograms;
    final isLoading = programProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtered Programs'),
        leading: BackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : programs.isEmpty
              ? const Center(child: Text('No active programs found.'))
              : ListView.separated(
                  itemCount: programs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final Program program = programs[index];
                    String categoryDisplay = program.category.isNotEmpty
                        ? program.category[0].toUpperCase() + program.category.substring(1).toLowerCase()
                        : '';
                    return ListTile(
                      title: Text(program.name),
                      subtitle: Text(categoryDisplay),
                      trailing: program.isSystemDefault
                          ? const Text('System', style: TextStyle(color: Colors.green))
                          : const Text('Custom', style: TextStyle(color: Colors.blue)),
                    );
                  },
                ),
    );
  }
} 