import 'package:json_annotation/json_annotation.dart';

part 'program.g.dart';

@JsonSerializable()
class Program {
  final String id;
  final String name;
  final String category;
  @JsonKey(name: 'systemDefault')
  final bool isSystemDefault;
  FinancialType financialType;
  @JsonKey(defaultValue: true)
  bool isEnabled;
  @JsonKey(name: 'isAssembly', defaultValue: false)
  final bool isAssembly;

  Program({
    required this.id,
    required this.name,
    required this.category,
    required this.isSystemDefault,
    this.financialType = FinancialType.both,
    this.isEnabled = true,
    required this.isAssembly,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      isSystemDefault: json['systemDefault'] as bool,
      financialType: json['financialType'] != null
          ? $enumDecodeNullable(_$FinancialTypeEnumMap, json['financialType']) ?? FinancialType.both
          : FinancialType.both,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isAssembly: json['isAssembly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$ProgramToJson(this);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'isSystemDefault': isSystemDefault,
    'financialType': financialType.name,
    'isEnabled': isEnabled,
    'isAssembly': isAssembly,
  };

  factory Program.fromMap(Map<String, dynamic> map) => Program(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    category: map['category'] ?? '',
    isSystemDefault: map['isSystemDefault'] ?? false,
    financialType: map['financialType'] != null 
        ? FinancialType.values.firstWhere(
            (e) => e.name == map['financialType'],
            orElse: () => FinancialType.both)
    : FinancialType.both,
    isEnabled: map['isEnabled'] ?? false,
    isAssembly: map['isAssembly'] ?? false,
  );
}

enum ProgramCategory {
  faith,
  family,
  community,
  life,
  patriotic,
}

enum FinancialType {
  expenseOnly,
  incomeOnly,
  both;

  String get displayName {
    switch (this) {
      case FinancialType.expenseOnly:
        return 'Expense Only';
      case FinancialType.incomeOnly:
        return 'Income Only';
      case FinancialType.both:
        return 'Income & Expense';
    }
  }
}

@JsonSerializable()
class ProgramsData {
  @JsonKey(name: 'council_programs')
  final Map<String, List<Program>> councilPrograms;
  @JsonKey(name: 'assembly_programs')
  final Map<String, List<Program>> assemblyPrograms;

  ProgramsData({
    required this.councilPrograms,
    required this.assemblyPrograms,
  });

  factory ProgramsData.fromJson(Map<String, dynamic> json) {
    // First deserialize the raw JSON
    final data = _$ProgramsDataFromJson(json);
    
    // Then update the isAssembly flag based on which list each program came from
    final updatedCouncilPrograms = data.councilPrograms.map(
      (k, programs) => MapEntry(k, programs.map((p) => Program(
        id: p.id,
        name: p.name,
        category: p.category,
        isSystemDefault: p.isSystemDefault,
        financialType: p.financialType,
        isEnabled: p.isEnabled,
        isAssembly: false,
      )).toList()),
    );

    final updatedAssemblyPrograms = data.assemblyPrograms.map(
      (k, programs) => MapEntry(k, programs.map((p) => Program(
        id: p.id,
        name: p.name,
        category: p.category,
        isSystemDefault: p.isSystemDefault,
        financialType: p.financialType,
        isEnabled: p.isEnabled,
        isAssembly: true,
      )).toList()),
    );

    return ProgramsData(
      councilPrograms: updatedCouncilPrograms,
      assemblyPrograms: updatedAssemblyPrograms,
    );
  }

  Map<String, dynamic> toJson() => _$ProgramsDataToJson(this);

  void updateProgramFinancialType(String programId, FinancialType newType) {
    // Update in council programs
    for (var programs in councilPrograms.values) {
      for (var program in programs) {
        if (program.id == programId) {
          program.financialType = newType;
          return;
        }
      }
    }
    
    // Update in assembly programs
    for (var programs in assemblyPrograms.values) {
      for (var program in programs) {
        if (program.id == programId) {
          program.financialType = newType;
          return;
        }
      }
    }
  }
} 