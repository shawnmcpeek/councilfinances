import 'package:json_annotation/json_annotation.dart';

part 'program.g.dart';

@JsonSerializable()
class Program {
  final String id;
  final String name;
  final String category;
  @JsonKey(name: 'systemDefault')
  final bool isSystemDefault;
  @JsonKey(defaultValue: 'both')
  FinancialType financialType;
  @JsonKey(defaultValue: true)
  bool isEnabled;

  Program({
    required this.id,
    required this.name,
    required this.category,
    required this.isSystemDefault,
    this.financialType = FinancialType.both,
    this.isEnabled = true,
  });

  factory Program.fromJson(Map<String, dynamic> json) => _$ProgramFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramToJson(this);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'isSystemDefault': isSystemDefault,
    'financialType': financialType.name,
    'isEnabled': isEnabled,
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

  factory ProgramsData.fromJson(Map<String, dynamic> json) => _$ProgramsDataFromJson(json);

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