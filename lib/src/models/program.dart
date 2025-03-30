import 'package:json_annotation/json_annotation.dart';

part 'program.g.dart';

@JsonSerializable()
class Program {
  final String id;
  final String name;
  final String category;
  @JsonKey(name: 'systemDefault')
  final bool isSystemDefault;
  @JsonKey(defaultValue: true)
  bool isEnabled;

  Program({
    required this.id,
    required this.name,
    required this.category,
    required this.isSystemDefault,
    this.isEnabled = true,
  });

  factory Program.fromJson(Map<String, dynamic> json) => _$ProgramFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramToJson(this);
}

enum ProgramCategory {
  FAITH,
  FAMILY,
  COMMUNITY,
  LIFE,
  PATRIOTIC,
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
    return ProgramsData(
      councilPrograms: _parsePrograms(json['council_programs'] as Map<String, dynamic>),
      assemblyPrograms: _parsePrograms(json['assembly_programs'] as Map<String, dynamic>),
    );
  }

  static Map<String, List<Program>> _parsePrograms(Map<String, dynamic> json) {
    return json.map((key, value) {
      final List<dynamic> programs = value as List<dynamic>;
      return MapEntry(
        key,
        programs.map((program) => Program.fromJson(program as Map<String, dynamic>)).toList(),
      );
    });
  }

  Map<String, dynamic> toJson() => _$ProgramsDataToJson(this);
} 