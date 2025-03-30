import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kcmanagement/firebase_options.dart';
import 'package:kcmanagement/src/screens/login_screen.dart';
import 'package:kcmanagement/src/screens/profile_screen.dart';
import 'package:kcmanagement/src/screens/home_screen.dart';
import 'package:kcmanagement/src/screens/programs_screen.dart';
import 'package:kcmanagement/src/services/auth_service.dart';
import 'package:kcmanagement/src/services/user_service.dart';
import 'package:kcmanagement/src/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kcmanagement/src/utils/logger.dart';
import 'package:kcmanagement/src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.init();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KC Management',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in, show main screen
          return const MainScreen();
        }

        // User is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _userService = UserService();
  UserProfile? _userProfile;
  String _selectedOrg = 'council';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user profile in MainScreen', e);
    }
  }

  String _getFormattedOrganizationId() {
    if (_userProfile == null) return '';
    
    if (_selectedOrg == 'assembly') {
      if (_userProfile?.assemblyNumber == null) return '';
      return 'A${_userProfile!.assemblyNumber.toString().padLeft(6, '0')}';
    } else {
      if (_userProfile?.councilNumber == null) return '';
      return 'C${_userProfile!.councilNumber.toString().padLeft(6, '0')}';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            onOrgChanged: (org) => setState(() => _selectedOrg = org),
          ),
          ProgramsScreen(
            initialIsAssembly: _selectedOrg == 'assembly',
            organizationId: _getFormattedOrganizationId(),
          ),
          const FinanceScreen(),
          const HoursScreen(),
          ProfileScreen(
            onProgramsPressed: () => _onItemTapped(1),  // 1 is the index of Programs tab
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Hours',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Finance',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class HoursScreen extends StatelessWidget {
  const HoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Hours'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Volunteer Hours',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
