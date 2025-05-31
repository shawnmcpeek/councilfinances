import 'package:flutter/material.dart';
import '../models/program.dart';
import '../services/program_service.dart';

class ProgramProvider extends ChangeNotifier {
  final ProgramService _programService = ProgramService();

  List<Program> _activePrograms = [];
  bool _isLoading = false;
  String? _organizationId;
  bool _isAssembly = false;

  List<Program> get activePrograms => _activePrograms;
  bool get isLoading => _isLoading;

  Future<void> loadPrograms({
    required String organizationId,
    required bool isAssembly,
  }) async {
    _isLoading = true;
    notifyListeners();
    _organizationId = organizationId;
    _isAssembly = isAssembly;

    try {
      // Load system programs
      final programsData = await _programService.loadSystemPrograms();
      // Load program states for the organization (updates isEnabled flags)
      await _programService.loadProgramStates(programsData, organizationId, isAssembly);
      final systemPrograms = isAssembly
          ? programsData.assemblyPrograms
          : programsData.councilPrograms;
      final activeSystemPrograms = systemPrograms.values
          .expand((list) => list)
          .where((program) => program.isEnabled)
          .toList();

      // Load custom programs
      final customPrograms = await _programService.getCustomPrograms(organizationId, isAssembly);
      final activeCustomPrograms = customPrograms.where((program) => program.isEnabled).toList();

      // Combine and sort
      _activePrograms = [
        ...activeSystemPrograms,
        ...activeCustomPrograms,
      ]..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _activePrograms = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optionally, allow manual reload
  void reload() {
    if (_organizationId != null) {
      loadPrograms(organizationId: _organizationId!, isAssembly: _isAssembly);
    }
  }
} 