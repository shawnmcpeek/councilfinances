import 'package:cloud_firestore/cloud_firestore.dart';

enum HoursCategory {
  faith,
  family,
  community,
  life,
  patriotic,
  assembly;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  bool get isAssemblyOnly => this == HoursCategory.patriotic || this == HoursCategory.assembly;
}

class HoursEntry {
  final String id;
  final String userId;
  final String organizationId;
  final bool isAssembly;
  final String programId;
  final String programName;
  final HoursCategory category;
  final Timestamp startTime;
  final Timestamp endTime;
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

  factory HoursEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HoursEntry(
      id: doc.id,
      userId: data['userId'] as String,
      organizationId: data['organizationId'] as String,
      isAssembly: data['isAssembly'] as bool? ?? false,
      programId: data['programId'] as String,
      programName: data['programName'] as String,
      category: HoursCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String? ?? 'faith'),
        orElse: () => HoursCategory.faith,
      ),
      startTime: data['startTime'] as Timestamp,
      endTime: data['endTime'] as Timestamp,
      totalHours: (data['totalHours'] as num).toDouble(),
      disbursement: (data['disbursement'] as num?)?.toDouble(),
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      'startTime': startTime,
      'endTime': endTime,
      'totalHours': totalHours,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (disbursement != null) {
      map['disbursement'] = disbursement as Object;
    }
    if (description?.isNotEmpty == true) {
      map['description'] = description as Object;
    }
    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
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
    Timestamp? startTime,
    Timestamp? endTime,
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
    final baseKey = '${category.name}_${programId}';
    return baseKey;
  }
} 