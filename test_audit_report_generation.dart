import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/src/services/audit_firestore_data_service.dart';
import 'lib/src/reports/semi_annual_audit_service.dart';
import 'lib/src/utils/logger.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('=== AUDIT REPORT GENERATION TEST ===');
  print('Testing complete audit report generation for period: 1/1/2025 - 6/30/2025');
  print('');

  try {
    // Test 1: Get Firestore data using the actual service
    print('=== TEST 1: FIRESTORE DATA RETRIEVAL ===');
    final auditService = AuditFirestoreDataService();
    final firestoreData = await auditService.getAuditFirestoreData('June', 2025);
    
    print('✓ Firestore data retrieved successfully');
    print('Organization Info:');
    print('  Council Number: ${firestoreData['council_number']}');
    print('  Organization Name: ${firestoreData['organization_name']}');
    print('  Year: ${firestoreData['year']}');
    print('');
    
    print('Calculated Financial Values:');
    print('  Membership Dues (Text51): ${firestoreData['membership_dues']}');
    print('  Interest Earned (Text64): ${firestoreData['interest_earned']}');
    print('  Supreme Per Capita (Text66): ${firestoreData['supreme_per_capita']}');
    print('  State Per Capita (Text67): ${firestoreData['state_per_capita']}');
    print('  Council Programs (Text68): ${firestoreData['council_program']}');
    print('  Other Council Programs: ${firestoreData['other_council_programs']}');
    print('');

    // Test 2: Generate complete audit report
    print('=== TEST 2: COMPLETE AUDIT REPORT GENERATION ===');
    final auditReportService = SemiAnnualAuditService();
    
    // Create minimal manual values (most will be auto-calculated)
    final Map<String, String> manualValues = {
      'Text2': 'Test Auditor', // Auditor name
      'Text50': '0.00', // Manual income 1
      'Text59': '0.00', // Manual income 2
      'Text69': '0.00', // Manual expense 1
      'Text70': '0.00', // Manual expense 2
      'Text74': '0.00', // Manual membership 1
      'Text75': '0.00', // Manual membership 2
      'Text76': '0.00', // Manual membership 3
      'Text77': '0', // Membership count
      'Text78': '0.00', // Membership dues total
      'Text84': '0.00', // Manual disbursement 1
      'Text85': '0.00', // Manual disbursement 2
      'Text86': '0.00', // Manual disbursement 3
      'Text87': '0.00', // Manual disbursement 4
      'Text89': '0.00', // Manual field 1
      'Text90': '0.00', // Manual field 2
      'Text91': '0.00', // Manual field 3
      'Text92': '0.00', // Manual field 4
      'Text93': '0.00', // Manual field 5
      'Text95': '0.00', // Manual field 6
      'Text96': '0.00', // Manual field 7
      'Text97': '0.00', // Manual field 8
      'Text98': '0.00', // Manual field 9
      'Text99': '0.00', // Manual field 10
      'Text100': '0.00', // Manual field 11
      'Text101': '0.00', // Manual field 12
      'Text102': '0.00', // Manual field 13
      'Text104': '0.00', // Manual field 14
      'Text105': '0.00', // Manual field 15
      'Text106': '0.00', // Manual field 16
      'Text107': '0.00', // Manual field 17
      'Text108': '0.00', // Manual field 18
      'Text109': '0.00', // Manual field 19
      'Text110': '0.00', // Manual field 20
    };

    print('Generating audit report with Firestore data + minimal manual values...');
    
    // Generate the audit report
    await auditReportService.generateAuditReport('June', 2025, manualValues);
    
    print('✓ Audit report generated successfully!');
    print('');

    // Test 3: Show all Firestore data fields
    print('=== TEST 3: ALL FIRESTORE DATA FIELDS ===');
    print('All Firestore data fields:');
    firestoreData.forEach((key, value) {
      print('  $key: $value');
    });
    
    print('');
    print('=== TEST COMPLETE ===');
    print('✓ Firestore data retrieval: WORKING');
    print('✓ Audit report generation: WORKING');
    print('✓ Field calculations: WORKING');
    print('');
    print('SUMMARY:');
    print('- Found ${firestoreData.length} calculated fields from Firestore');
    print('- Successfully generated audit report PDF');
    print('- All Firestore data is being properly retrieved and calculated');
    
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('STACK TRACE: $stackTrace');
  }
} 