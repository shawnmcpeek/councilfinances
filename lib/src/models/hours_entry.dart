import 'package:cloud_firestore/cloud_firestore.dart';

class HoursEntry {
  final String id;
  final String userId;
  final String organizationId;
  final String programId;
  final String programName;
  final Timestamp startTime;
  final Timestamp endTime;
  final double totalHours;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HoursEntry({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.programId,
    required this.programName,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.createdAt,
    this.updatedAt,
  });

  factory HoursEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HoursEntry(
      id: doc.id,
      userId: data['userId'] as String,
      organizationId: data['organizationId'] as String,
      programId: data['programId'] as String,
      programName: data['programName'] as String,
      startTime: data['startTime'] as Timestamp,
      endTime: data['endTime'] as Timestamp,
      totalHours: (data['totalHours'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'programId': programId,
      'programName': programName,
      'startTime': startTime,
      'endTime': endTime,
      'totalHours': totalHours,
    };
  }

  HoursEntry copyWith({
    String? id,
    String? userId,
    String? organizationId,
    String? programId,
    String? programName,
    Timestamp? startTime,
    Timestamp? endTime,
    double? totalHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HoursEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalHours: totalHours ?? this.totalHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 