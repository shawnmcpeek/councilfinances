import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('=== AUDIT FIRESTORE DATA TEST ===');
  print('Testing data retrieval for period: 1/1/2025 - 6/30/2025');
  print('');

  try {
    final db = FirebaseFirestore.instance;
    
    // Test with a specific organization ID (you can change this)
    final organizationId = 'C015857'; // Council 15857
    final startDate = DateTime(2025, 1, 1);
    final endDate = DateTime(2025, 6, 30);
    
    print('Organization ID: $organizationId');
    print('Date range: ${startDate.toString()} to ${endDate.toString()}');
    print('');

    // Test 1: Check if organization exists
    print('=== TEST 1: CHECK ORGANIZATION ===');
    final orgDoc = await db.collection('organizations').doc(organizationId).get();
    if (orgDoc.exists) {
      print('✓ Organization exists');
      print('Organization data: ${orgDoc.data()}');
    } else {
      print('✗ Organization not found');
    }
    print('');

    // Test 2: Check income transactions
    print('=== TEST 2: INCOME TRANSACTIONS ===');
    final incomeSnapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('finance')
        .doc('income')
        .collection('2025')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
        
    print('Found ${incomeSnapshot.docs.length} income transactions');
    for (final doc in incomeSnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
      final description = data['description'] ?? 'N/A';
      
      print('  INCOME: Date: $date, Amount: \$${amount.toStringAsFixed(2)}, Program: $program, Description: $description');
    }
    print('');

    // Test 3: Check expense transactions
    print('=== TEST 3: EXPENSE TRANSACTIONS ===');
    final expenseSnapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('finance')
        .doc('expenses')
        .collection('2025')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
        
    print('Found ${expenseSnapshot.docs.length} expense transactions');
    for (final doc in expenseSnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      final program = data['programName'] ?? data['program']?['name'] ?? 'Unknown';
      final description = data['description'] ?? 'N/A';
      
      print('  EXPENSE: Date: $date, Amount: \$${amount.toStringAsFixed(2)}, Program: $program, Description: $description');
    }
    print('');

    // Test 4: Calculate audit fields
    print('=== TEST 4: AUDIT FIELD CALCULATIONS ===');
    final allTransactions = <Map<String, dynamic>>[];
    
    // Add income transactions
    for (final doc in incomeSnapshot.docs) {
      final data = doc.data();
      allTransactions.add({
        'program': data['programName'] ?? data['program']?['name'] ?? 'Unknown',
        'amount': (data['amount'] as num).toDouble(),
        'type': 'income',
        'date': (data['date'] as Timestamp).toDate(),
      });
    }
    
    // Add expense transactions
    for (final doc in expenseSnapshot.docs) {
      final data = doc.data();
      allTransactions.add({
        'program': data['programName'] ?? data['program']?['name'] ?? 'Unknown',
        'amount': (data['amount'] as num).toDouble(),
        'type': 'expense',
        'date': (data['date'] as Timestamp).toDate(),
      });
    }
    
    // Calculate totals
    double membershipDues = 0.0;
    double interestEarned = 0.0;
    double supremePerCapita = 0.0;
    double statePerCapita = 0.0;
    double councilPrograms = 0.0;
    double otherCouncilPrograms = 0.0;
    
    for (final transaction in allTransactions) {
      final programName = (transaction['program'] as String).toLowerCase();
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;
      
      if (type == 'income') {
        if (programName.contains('membership') || programName.contains('dues')) {
          membershipDues += amount;
        } else if (programName.contains('interest')) {
          interestEarned += amount;
        } else if (programName.contains('supreme') || programName.contains('per capita')) {
          supremePerCapita += amount;
        } else if (programName.contains('state')) {
          statePerCapita += amount;
        } else {
          councilPrograms += amount;
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
    
    print('Calculated Audit Fields:');
    print('  Membership Dues (Text51): \$${membershipDues.toStringAsFixed(2)}');
    print('  Interest Earned (Text64): \$${interestEarned.toStringAsFixed(2)}');
    print('  Supreme Per Capita (Text66): \$${supremePerCapita.toStringAsFixed(2)}');
    print('  State Per Capita (Text67): \$${statePerCapita.toStringAsFixed(2)}');
    print('  Council Programs (Text68): \$${councilPrograms.toStringAsFixed(2)}');
    print('  Other Council Programs: \$${otherCouncilPrograms.toStringAsFixed(2)}');
    print('');
    
    print('=== TEST COMPLETE ===');
    print('Total transactions processed: ${allTransactions.length}');
    
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('STACK TRACE: $stackTrace');
  }
} 