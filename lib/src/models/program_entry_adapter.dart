import '../components/log_display.dart';
import '../models/form1728p_program.dart';
import '../utils/formatters.dart';

class ProgramEntry {
  final String id;
  final DateTime date;
  final Form1728PCategory category;
  final Form1728PProgram program;
  final int hours;
  final double disbursement;
  final String description;

  ProgramEntry({
    required this.id,
    required this.date,
    required this.category,
    required this.program,
    required this.hours,
    required this.disbursement,
    required this.description,
  });
}

class ProgramEntryAdapter implements LogEntry {
  final ProgramEntry entry;
  final bool hasEditPermission;
  final bool hasDeletePermission;

  ProgramEntryAdapter(this.entry, {
    this.hasEditPermission = false,
    this.hasDeletePermission = false,
  });

  @override
  String get id => entry.id;

  @override
  DateTime get date => entry.date;

  @override
  String get title => entry.program.name;

  @override
  String get subtitle => '${entry.hours} hrs, ${formatCurrency(entry.disbursement)}';

  @override
  Map<String, String> get details => {
    'Date': formatDate(entry.date),
    'Category': entry.category.displayName,
    'Program': entry.program.name,
    'Hours': '${entry.hours}',
    'Disbursement': formatCurrency(entry.disbursement),
    'Description': entry.description,
  };

  @override
  bool get canEdit => hasEditPermission;

  @override
  bool get canDelete => hasDeletePermission;
} 