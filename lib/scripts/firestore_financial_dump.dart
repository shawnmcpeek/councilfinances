import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:io';
import '../../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Financial Dump',
      home: const DumpScreen(),
    );
  }
}

class DumpScreen extends StatefulWidget {
  const DumpScreen({super.key});

  @override
  State<DumpScreen> createState() => _DumpScreenState();
}

class _DumpScreenState extends State<DumpScreen> {
  @override
  void initState() {
    super.initState();
    _dumpData();
  }

  Future<void> _dumpData() async {
    // TODO: Replace with your actual org ID and year, or parse from args
    const organizationId = 'C015857'; // Example: 'C015857'
    const year = '2025';
    const isAssembly = false;

    final firestore = FirebaseFirestore.instance;

    final incomeRef = firestore
        .collection("organizations")
        .doc(organizationId)
        .collection("finance")
        .doc("income")
        .collection(year);
    final expenseRef = firestore
        .collection("organizations")
        .doc(organizationId)
        .collection("finance")
        .doc("expenses")
        .collection(year);

    final incomeSnapshot = await incomeRef.get();
    final expenseSnapshot = await expenseRef.get();

    final incomeDocs = incomeSnapshot.docs;
    final expenseDocs = expenseSnapshot.docs;

    final incomeData = incomeDocs.map((e) => e.data()).toList();
    final expenseData = expenseDocs.map((e) => e.data()).toList();

    final dump = {
      "organizationId": organizationId,
      "year": year,
      "isAssembly": isAssembly,
      "income": incomeData,
      "expenses": expenseData,
    };

    print("FIRE STORE DUMP (ORGANIZATION FINANCIAL DATA):");
    print(JsonEncoder.withIndent("  ").convert(_convertTimestamps(dump)));

    // === BEGIN AUDIT FIELD CALCULATIONS ===
    // Only consider entries within the selected period (Jan-Jun or Jul-Dec)
    DateTime periodStart = DateTime.parse('$year-01-01');
    DateTime periodEnd = DateTime.parse('$year-06-30');
    // TODO: Make this dynamic based on period selection

    // Combine all entries (income + expenses)
    final allEntries = [...incomeData, ...expenseData];

    // Filter for period
    final periodEntries = allEntries.where((entry) {
      final rawDate = entry['date'];
      DateTime date;
      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is String) {
        date = DateTime.tryParse(rawDate) ?? DateTime(1900);
      } else {
        date = DateTime(1900);
      }
      return date.isAfter(periodStart.subtract(const Duration(days: 1))) && date.isBefore(periodEnd.add(const Duration(days: 1)));
    }).toList();

    // Text51: Total of all 'Council - Membership Dues'
    final membershipDuesEntries = periodEntries.where((entry) {
      final programName = entry['programName'] ?? entry['program']?['name'] ?? '';
      return programName.toLowerCase().contains('membership dues');
    });
    final text51 = membershipDuesEntries.fold(0.0, (sum, e) => sum + (e['amount'] ?? 0));

    // Group all income (excluding membership dues) by program
    final incomeEntries = periodEntries.where((entry) {
      final isExpense = entry['isExpense'] ?? false;
      return !isExpense;
    }).where((entry) {
      final programName = entry['programName'] ?? entry['program']?['name'] ?? '';
      return !programName.toLowerCase().contains('membership dues');
    }).toList();

    final Map<String, double> incomeByProgram = {};
    for (final entry in incomeEntries) {
      final programName = entry['programName'] ?? entry['program']?['name'] ?? 'Unknown';
      incomeByProgram[programName] = (incomeByProgram[programName] ?? 0) + (entry['amount'] ?? 0);
    }
    // Sort by total descending
    final sortedPrograms = incomeByProgram.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 2 programs
    final top1 = sortedPrograms.isNotEmpty ? sortedPrograms[0] : null;
    final top2 = sortedPrograms.length > 1 ? sortedPrograms[1] : null;
    final others = sortedPrograms.length > 2 ? sortedPrograms.sublist(2) : [];

    final text52 = top1?.key ?? '';
    final text53 = top1?.value ?? 0.0;
    final text54 = top2?.key ?? '';
    final text55 = top2?.value ?? 0.0;
    final text56 = others.isNotEmpty ? 'Other' : '';
    final text57 = others.fold(0.0, (sum, e) => sum + e.value);

    // Text58: Text50 (manual), Text51, Text53, Text55, Text57
    // We'll use 0 for Text50 (manual) for now
    final text50 = 0.0;
    final text58 = text50 + text51 + text53 + text55 + text57;

    String fmt(num n) => n.toStringAsFixed(2);

    print('\n=== AUDIT FIELD CALCULATIONS ===');
    print('Text51 (Membership Dues):              \t' + fmt(text51));
    print('Text52 (Top Program Name):              \t$text52');
    print('Text53 (Top Program Total):             \t' + fmt(text53));
    print('Text54 (2nd Program Name):              \t$text54');
    print('Text55 (2nd Program Total):             \t' + fmt(text55));
    print('Text56 (Other):                         \t$text56');
    print('Text57 (Other Total):                   \t' + fmt(text57));
    print('Text58 (Sum):                           \t' + fmt(text58));

    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Dumping Firestore data to console… (see your terminal)"),
      ),
    );
  }
}

dynamic _convertTimestamps(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _convertTimestamps(v)));
  } else if (value is List) {
    return value.map(_convertTimestamps).toList();
  } else if (value is Timestamp) {
    return value.toDate().toIso8601String();
  } else {
    return value;
  }
} 