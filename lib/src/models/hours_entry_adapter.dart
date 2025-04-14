import '../components/log_display.dart';
import '../models/hours_entry.dart';
import '../utils/formatters.dart';

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
  String get subtitle => '${entry.totalHours} hours';

  @override
  Map<String, String> get details => {
    'Start Time': formatTime(entry.startTime.toDate()),
    'End Time': formatTime(entry.endTime.toDate()),
    'Total Hours': entry.totalHours.toString(),
  };

  @override
  bool get canEdit => hasEditPermission;

  @override
  bool get canDelete => hasDeletePermission;
} 