// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Program _$ProgramFromJson(Map<String, dynamic> json) => Program(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      isSystemDefault: json['systemDefault'] as bool,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$ProgramToJson(Program instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'systemDefault': instance.isSystemDefault,
      'isEnabled': instance.isEnabled,
    };

ProgramsData _$ProgramsDataFromJson(Map<String, dynamic> json) => ProgramsData(
      councilPrograms: (json['council_programs'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => Program.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      assemblyPrograms: (json['assembly_programs'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => Program.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$ProgramsDataToJson(ProgramsData instance) =>
    <String, dynamic>{
      'council_programs': instance.councilPrograms,
      'assembly_programs': instance.assemblyPrograms,
    };
