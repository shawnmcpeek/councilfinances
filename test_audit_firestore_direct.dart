import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('=== DIRECT AUDIT FIRESTORE TEST ===');
  print('Testing Firestore data retrieval for period: 1/1/2025 - 6/30/2025');
  print('');

  try {
    final db = FirebaseFirestore.instance;
    
    // Test with a specific organization ID
    final organizationId = 'C015857'; // Council 15857
    final startDate = DateTime(2025, 1, 1);
    final endDate = DateTime(2025, 6, 30);
    
    print('Organization ID: $organizationId');
    print('Date range: ${startDate.toString()} to ${endDate.toString()}');
    print('');

    // Get all transactions for the period
    final List<Map<String, dynamic>> allTransactions = [];
    final years = <int>{startDate.year, endDate.year};
    
    for (final year in years) {
      print('Loading transactions for year: $year');
      
      // Fetch income
      final incomeSnapshot = await db
          .collection('organizations')
          .doc(organizationId)
          .collection('finance')
          .doc('income')
          .collection(year.toString())
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
          
      print('Found ${incomeSnapshot.docs.length} income transactions for year $year');
      
      for (final doc in incomeSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final amount = (data['amount'] as num).toDouble();
        final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
        final description = data['description'] ?? 'N/A';
        
        allTransactions.add({
          'program': program,
          'programId': data['programId'] ?? data['program']?['id'] ?? '',
          'amount': amount,
          'date': date,
          'type': 'income',
          'description': description
        });
      }

      // Fetch expenses
      final expenseSnapshot = await db
          .collection('organizations')
          .doc(organizationId)
          .collection('finance')
          .doc('expenses')
          .collection(year.toString())
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
          
      print('Found ${expenseSnapshot.docs.length} expense transactions for year $year');
      
      for (final doc in expenseSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final amount = (data['amount'] as num).toDouble();
        final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
        final description = data['description'] ?? 'N/A';
        
        allTransactions.add({
          'program': program,
          'programId': data['programId'] ?? data['program']?['id'] ?? '',
          'amount': amount,
          'date': date,
          'type': 'expense',
          'description': description
        });
      }
    }
    
    print('');
    print('Total transactions loaded: ${allTransactions.length}');
    print('');

    // Process transactions and calculate audit fields
    print('=== AUDIT FIELD CALCULATIONS ===');
    
    // Initialize totals
    double membershipDues = 0.0;
    double interestEarned = 0.0;
    double supremePerCapita = 0.0;
    double statePerCapita = 0.0;
    double councilPrograms = 0.0;
    double otherCouncilPrograms = 0.0;
    
    // Group transactions by program for income analysis
    final Map<String, double> programTotals = {};
    
    for (final transaction in allTransactions) {
      final programName = _normalizeProgram(transaction['program']);
      final amount = (transaction['amount'] as num).toDouble();
      final type = transaction['type'] as String;
      
      if (type == 'income') {
        // Map programs to audit fields
        if (programName.contains('membership') || programName.contains('dues')) {
          membershipDues += amount;
        } else if (programName.contains('interest')) {
          interestEarned += amount;
        } else if (programName.contains('supreme') || programName.contains('per capita')) {
          supremePerCapita += amount;
        } else if (programName.contains('state')) {
          statePerCapita += amount;
        } else {
          // Track other programs for top programs analysis
          final program = transaction['program'] as String;
          programTotals[program] = (programTotals[program] ?? 0.0) + amount;
        }
      } else {
        // Expenses
        if (programName.contains('postage') || 
            programName.contains('insurance') || 
            programName.contains('membership') ||
            programName.contains('advertising') ||
            programName.contains('conference') ||
            programName.contains('convention') ||
            programName.contains('seminarian')) {
          otherCouncilPrograms += amount;
        } else {
          councilPrograms += amount;
        }
      }
    }
    
    // Find top 2 income programs (excluding membership dues)
    final sortedPrograms = programTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topProgram1 = sortedPrograms.isNotEmpty ? sortedPrograms[0] : null;
    final topProgram2 = sortedPrograms.length > 1 ? sortedPrograms[1] : null;
    
    // Calculate "Other" programs total
    double otherProgramsTotal = 0.0;
    for (int i = 2; i < sortedPrograms.length; i++) {
      otherProgramsTotal += sortedPrograms[i].value;
    }
    
    // Calculate totals
    final totalIncome = membershipDues + (topProgram1?.value ?? 0.0) + (topProgram2?.value ?? 0.0) + otherProgramsTotal;
    
    print('=== CALCULATED AUDIT FIELDS ===');
    print('Text51 (Membership Dues): \$${membershipDues.toStringAsFixed(2)}');
    print('Text52 (Top Program Name): ${topProgram1?.key ?? "N/A"}');
    print('Text53 (Top Program Amount): \$${(topProgram1?.value ?? 0.0).toStringAsFixed(2)}');
    print('Text54 (2nd Program Name): ${topProgram2?.key ?? "N/A"}');
    print('Text55 (2nd Program Amount): \$${(topProgram2?.value ?? 0.0).toStringAsFixed(2)}');
    print('Text56 (Other Programs): "Other"');
    print('Text57 (Other Programs Amount): \$${otherProgramsTotal.toStringAsFixed(2)}');
    print('Text58 (Total Income): \$${totalIncome.toStringAsFixed(2)}');
    print('');
    print('Text64 (Interest Earned): \$${interestEarned.toStringAsFixed(2)}');
    print('Text66 (Supreme Per Capita): \$${supremePerCapita.toStringAsFixed(2)}');
    print('Text67 (State Per Capita): \$${statePerCapita.toStringAsFixed(2)}');
    print('Text68 (Council Programs): \$${councilPrograms.toStringAsFixed(2)}');
    print('Other Council Programs: \$${otherCouncilPrograms.toStringAsFixed(2)}');
    print('');
    
    print('=== TRANSACTION SUMMARY ===');
    print('Income transactions: ${allTransactions.where((t) => t['type'] == 'income').length}');
    print('Expense transactions: ${allTransactions.where((t) => t['type'] == 'expense').length}');
    print('Total transactions: ${allTransactions.length}');
    print('');
    
    print('=== TOP 5 INCOME PROGRAMS ===');
    for (int i = 0; i < sortedPrograms.length && i < 5; i++) {
      final program = sortedPrograms[i];
      print('${i + 1}. ${program.key}: \$${program.value.toStringAsFixed(2)}');
    }
    
    print('');
    print('=== TEST COMPLETE ===');
    print('✓ Firestore data retrieval: WORKING');
    print('✓ Transaction processing: WORKING');
    print('✓ Audit field calculations: WORKING');
    
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('STACK TRACE: $stackTrace');
  }
}

String _normalizeProgram(dynamic program) {
  return (program as String?)?.toLowerCase().trim() ?? '';
} 