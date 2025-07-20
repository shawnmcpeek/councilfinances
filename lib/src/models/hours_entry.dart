enum HoursCategory {
  faith,
  family,
  community,
  life,
  patriotic;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  bool get isAssemblyOnly => this == HoursCategory.patriotic;
}

class HoursEntry {
  final String id;
  final String userId;
  final String organizationId;
  final bool isAssembly;
  final String programId;
  final String programName;
  final HoursCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final double totalHours;
  final double? disbursement;  // Optional disbursement amount
  final String? description;   // Optional description
  final DateTime createdAt;
  final DateTime? updatedAt;

  HoursEntry({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.isAssembly,
    required this.programId,
    required this.programName,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    this.disbursement,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory HoursEntry.fromMap(Map<String, dynamic> data) {
    return HoursEntry(
      id: data['id'] as String,
      userId: data['userId'] as String,
      organizationId: data['organizationId'] as String,
      isAssembly: data['isAssembly'] as bool? ?? false,
      programId: data['programId'] as String,
      programName: data['programName'] as String,
      category: HoursCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String? ?? 'faith'),
        orElse: () => HoursCategory.faith,
      ),
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: DateTime.parse(data['endTime'] as String),
      totalHours: (data['totalHours'] as num).toDouble(),
      disbursement: (data['disbursement'] as num?)?.toDouble(),
      description: data['description'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      'organizationId': organizationId,
      'isAssembly': isAssembly,
      'programId': programId,
      'programName': programName,
      'category': category.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalHours': totalHours,
      'createdAt': createdAt.toIso8601String(),
    };

    if (disbursement != null) {
      map['disbursement'] = disbursement as Object;
    }
    if (description?.isNotEmpty == true) {
      map['description'] = description as Object;
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  HoursEntry copyWith({
    String? id,
    String? userId,
    String? organizationId,
    bool? isAssembly,
    String? programId,
    String? programName,
    HoursCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    double? totalHours,
    double? disbursement,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HoursEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      isAssembly: isAssembly ?? this.isAssembly,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalHours: totalHours ?? this.totalHours,
      disbursement: disbursement ?? this.disbursement,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get the form field key for this entry
  String? getFormFieldKey() {
    final baseKey = '${category.name}_$programId';
    return baseKey;
  }
} 