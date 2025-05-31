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
      financialType:
          $enumDecodeNullable(_$FinancialTypeEnumMap, json['financialType']) ??
              FinancialType.both,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isAssembly: json['isAssembly'] as bool? ?? false,
    );

Map<String, dynamic> _$ProgramToJson(Program instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'systemDefault': instance.isSystemDefault,
      'financialType': _$FinancialTypeEnumMap[instance.financialType]!,
      'isEnabled': instance.isEnabled,
      'isAssembly': instance.isAssembly,
    };

const _$FinancialTypeEnumMap = {
  FinancialType.expenseOnly: 'expenseOnly',
  FinancialType.incomeOnly: 'incomeOnly',
  FinancialType.both: 'both',
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
