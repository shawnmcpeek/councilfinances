import 'finance_service.dart';
import 'hours_service.dart';
import 'mock_finance_service.dart';
import 'mock_hours_service.dart';

class ServiceFactory {
  static bool _useMockServices = false;

  // Toggle between real and mock services
  static void setUseMockServices(bool useMock) {
    _useMockServices = useMock;
  }

  // Get the appropriate finance service
  static dynamic getFinanceService() {
    return _useMockServices ? MockFinanceService() : FinanceService();
  }

  // Get the appropriate hours service
  static dynamic getHoursService() {
    return _useMockServices ? MockHoursService() : HoursService();
  }

  // Check if currently using mock services
  static bool get isUsingMockServices => _useMockServices;
} 