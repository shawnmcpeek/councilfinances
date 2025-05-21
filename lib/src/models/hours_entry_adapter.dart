import '../components/log_display.dart';
import '../models/hours_entry.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';

class HoursEntryAdapter implements LogEntry {
  final HoursEntry entry;
  final bool hasEditPermission;
  final bool hasDeletePermission;

  HoursEntryAdapter(this.entry, {
    this.hasEditPermission = false,
    this.hasDeletePermission = false,
  });

  @override
  String get id => entry.id;

  @override
  DateTime get date => entry.startTime.toDate();

  @override
  String get title => entry.programName;

  @override
  String get subtitle => [
    '${entry.totalHours} hours',
    if (entry.disbursement != null) '${formatCurrency(entry.disbursement!)}',
  ].join(', ');

  @override
  Map<String, String> get details => {
    'Category': entry.category.displayName,
    'Start Time': formatTime(entry.startTime.toDate()),
    'End Time': formatTime(entry.endTime.toDate()),
    'Total Hours': entry.totalHours.toString(),
    if (entry.disbursement != null)
      'Disbursement': formatCurrency(entry.disbursement!),
    if (entry.description?.isNotEmpty == true)
      'Description': entry.description!,
  };

  @override
  bool get canEdit => hasEditPermission;

  @override
  bool get canDelete => hasDeletePermission;

  @override
  BoxDecoration? get decoration => null;
} 