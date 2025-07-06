import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/service_factory.dart';
import '../services/mock_finance_service.dart';
import '../services/mock_hours_service.dart';
import '../models/finance_entry.dart';
import '../models/hours_entry.dart';
import '../models/program.dart';
import '../models/payment_method.dart';
import '../utils/logger.dart';

class MockServiceExample {
  static void demonstrateMockServices() async {
    AppLogger.info('=== MOCK SERVICE DEMONSTRATION ===');
    
    // Enable mock services
    ServiceFactory.setUseMockServices(true);
    AppLogger.info('Mock services enabled: ${ServiceFactory.isUsingMockServices}');
    
    // Get mock services
    final financeService = ServiceFactory.getFinanceService() as MockFinanceService;
    final hoursService = ServiceFactory.getHoursService() as MockHoursService;
    
    try {
      // Demonstrate finance service
      AppLogger.info('\n--- Finance Service Demo ---');
      final financeEntries = await financeService.getFinanceEntries('15857', false);
      AppLogger.info('Retrieved ${financeEntries.length} finance entries');
      
      // Add a new mock finance entry
      await financeService.addIncomeEntry(
        organizationId: '15857',
        isAssembly: false,
        date: DateTime.now(),
        amount: 100.0,
        description: 'Test income entry',
        paymentMethod: PaymentMethod.cash,
        programId: 'test-program',
        programName: 'Test Program',
      );
      
      // Demonstrate hours service
      AppLogger.info('\n--- Hours Service Demo ---');
      final hoursStream = hoursService.getHoursEntries('15857', false);
      await for (final hoursEntries in hoursStream) {
        AppLogger.info('Retrieved ${hoursEntries.length} hours entries');
        break; // Just get the first emission
      }
      
      // Add a new mock hours entry
      await hoursService.addHoursEntry(
        HoursEntry(
          id: 'test-id',
          userId: 'test-user',
          organizationId: '15857',
          isAssembly: false,
          programId: 'test-program',
          programName: 'Test Program',
          category: HoursCategory.community,
          startTime: Timestamp.fromDate(DateTime.now()),
          endTime: Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))),
          totalHours: 2.0,
          description: 'Test hours entry',
          disbursement: 0.0,
          createdAt: DateTime.now(),
        ),
        false,
      );
      
      AppLogger.info('\n--- Mock Service Demo Complete ---');
      
    } catch (e) {
      AppLogger.error('Error in mock service demonstration', e);
    }
  }
  
  static void demonstrateServiceSwitching() {
    AppLogger.info('\n=== SERVICE SWITCHING DEMONSTRATION ===');
    
    // Start with real services
    ServiceFactory.setUseMockServices(false);
    AppLogger.info('Using real services: ${!ServiceFactory.isUsingMockServices}');
    
    // Switch to mock services
    ServiceFactory.setUseMockServices(true);
    AppLogger.info('Switched to mock services: ${ServiceFactory.isUsingMockServices}');
    
    // Switch back to real services
    ServiceFactory.setUseMockServices(false);
    AppLogger.info('Switched back to real services: ${!ServiceFactory.isUsingMockServices}');
  }
  
  static void demonstrateCustomMockData() {
    AppLogger.info('\n=== CUSTOM MOCK DATA DEMONSTRATION ===');
    
    final financeService = MockFinanceService();
    final hoursService = MockHoursService();
    
    // Clear existing mock data
    financeService.clearMockData();
    hoursService.clearMockData();
    
    // Add custom mock data
    financeService.addMockEntry(
      FinanceEntry(
        id: 'custom-1',
        date: DateTime.now(),
        program: Program(
          id: 'custom-program',
          name: 'Custom Program',
          category: 'custom',
          isSystemDefault: false,
          financialType: FinancialType.incomeOnly,
          isEnabled: true,
          isAssembly: false,
        ),
        amount: 500.0,
        paymentMethod: 'Custom Payment',
        checkNumber: null,
        description: 'Custom finance entry',
        isExpense: false,
      ),
    );
    
    hoursService.addMockEntry(
      HoursEntry(
        id: 'custom-hours-1',
        userId: 'custom-user',
        organizationId: 'C015857',
        isAssembly: false,
        programId: 'custom-program',
        programName: 'Custom Program',
        category: HoursCategory.community,
        startTime: Timestamp.fromDate(DateTime.now()),
        endTime: Timestamp.fromDate(DateTime.now().add(Duration(hours: 5))),
        totalHours: 5.0,
        description: 'Custom hours entry',
        disbursement: 0.0,
        createdAt: DateTime.now(),
      ),
    );
    
    AppLogger.info('Added custom mock data to both services');
  }
} 