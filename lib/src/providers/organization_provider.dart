import 'package:flutter/foundation.dart';

class OrganizationProvider extends ChangeNotifier {
  bool _isAssembly = false; // Default to Council (false)

  bool get isAssembly => _isAssembly;

  void toggleOrganization() {
    _isAssembly = !_isAssembly;
    notifyListeners();
  }

  void setOrganization(bool isAssembly) {
    if (_isAssembly != isAssembly) {
      _isAssembly = isAssembly;
      notifyListeners();
    }
  }
} 