import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:knights_management/src/screens/login_screen.dart';
import 'package:knights_management/src/screens/profile_screen.dart';
import 'package:knights_management/src/screens/home_screen.dart';
import 'package:knights_management/src/screens/programs_collect.dart';
import 'package:knights_management/src/screens/hours_entry_screen.dart';
import 'package:knights_management/src/screens/finance_screen.dart';
import 'package:knights_management/src/screens/programs_screen.dart';
import 'package:knights_management/src/screens/reports_screen.dart';
import 'package:knights_management/src/screens/periodic_report_data.dart';
import 'package:knights_management/src/screens/subscription_screen.dart';
import 'package:knights_management/src/screens/reimbursement_request_screen.dart';
import 'package:knights_management/src/services/auth_service.dart';
import 'package:knights_management/src/services/user_service.dart';
import 'package:knights_management/src/services/subscription_service.dart';
import 'package:knights_management/src/services/access_control_service.dart';
import 'package:knights_management/src/utils/logger.dart';
import 'package:knights_management/src/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'src/providers/organization_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/reports/form1728_report_service.dart';
import 'src/reports/volunteer_hours_report_service.dart';
import 'src/reports/pdf_template_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.init();
    
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://fwcqtjsqetqavdhkahzy.supabase.co',
      anonKey: 'sb_publishable_H6iglIKUpKGjz-sA6W2PGA_3p7vqL7G',
    );
    
    // Initialize RevenueCat
    await SubscriptionService().initialize();
    
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isAndroid || Platform.isIOS)) {
      await getApplicationDocumentsDirectory().then((directory) {
        AppLogger.debug('Application documents directory initialized: \\${directory.path}');
      }).catchError((e) {
        AppLogger.error('Failed to initialize application documents directory', e);
      });
    } else {
      AppLogger.debug('Application documents directory not supported on this platform.');
    }
    initializeTemplates();
    AppLogger.debug('PDF templates initialized');
    final userService = UserService();
    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => OrganizationProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          Provider<SubscriptionService>(create: (_) => SubscriptionService()),
          Provider<AccessControlService>(create: (_) => AccessControlService()),
          Provider<Form1728ReportService>(create: (_) => Form1728ReportService()),
          Provider<VolunteerHoursReportService>(
            create: (_) => VolunteerHoursReportService(userService, Supabase.instance.client),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    AppLogger.error('Error initializing app', e, stackTrace);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: const ValueKey('root_app'),
      debugShowCheckedModeBanner: false,
      title: 'KC Management',
      theme: AppTheme.lightTheme,
      navigatorKey: GlobalKey<NavigatorState>(),
      home: const AuthWrapper(),
      routes: {
        '/auditData': (context) => const PeriodicReportDataScreen(),
      },
    );
  }
}

// The AuthWrapper will handle authentication and show either the MainScreen or LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final authState = snapshot.data;
        final hasUser = authState?.session != null;
        return hasUser ? const MainScreen() : const LoginScreen();
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
  final AccessControlService _accessControl = AccessControlService();
  List<String> _visibleItems = ['home', 'profile'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load profile after initial build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccessPermissions();
    });
  }

  Future<void> _loadAccessPermissions() async {
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserProfile();
      
      if (!mounted) return;
      
      final userProfile = userProvider.userProfile;
      if (userProfile != null) {
        final needsSubscription = await _accessControl.shouldRedirectToSubscription(userProfile);
        
        if (needsSubscription) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/subscription');
          }
          return;
        }
        
        final visibleItems = await _accessControl.getVisibleNavigationItems(userProfile);
        
        if (mounted) {
          setState(() {
            _visibleItems = visibleItems;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      AppLogger.error('Error loading access permissions', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleProgramsPressed() async {
    if (!mounted) return;
    
    try {
      final userProvider = context.read<UserProvider>();
      final userProfile = userProvider.userProfile;
      
      if (userProfile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User profile not found')),
        );
        return;
      }

      if (!mounted) return;
      final isAssembly = userProfile.assemblyNumber != null;
      final organizationId = isAssembly 
          ? 'A${userProfile.assemblyNumber.toString().padLeft(6, '0')}'
          : 'C${userProfile.councilNumber.toString().padLeft(6, '0')}';

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramsScreen(
            organizationId: organizationId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _onDestinationSelected(int index) async {
    try {
      final userProvider = context.read<UserProvider>();
      final userProfile = userProvider.userProfile;
      if (!mounted || userProfile == null) return;
      
      // Check if user needs subscription for this navigation
      final needsSubscription = await _accessControl.shouldRedirectToSubscription(userProfile);
      
      if (needsSubscription) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(),
          ),
        );
        return;
      }
      
      if (mounted) {
        setState(() => _selectedIndex = index);
      }
    } catch (e) {
      AppLogger.error('Error handling navigation', e);
      if (mounted) {
        setState(() => _selectedIndex = index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = <Widget>[
      const HomeScreen(),
      if (_visibleItems.contains('programs')) const ProgramsCollectScreen(),
      if (_visibleItems.contains('hours')) const HoursEntryScreen(),
      if (_visibleItems.contains('finance')) const FinanceScreen(),
      if (_visibleItems.contains('reports')) const ReportsScreen(),
      if (_visibleItems.contains('reimbursement')) const ReimbursementRequestScreen(),
      ProfileScreen(
        onProgramsPressed: _handleProgramsPressed,
      ),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      if (_visibleItems.contains('programs'))
        const NavigationDestination(
          icon: Icon(Icons.assignment),
          label: 'Programs',
        ),
      if (_visibleItems.contains('hours'))
        const NavigationDestination(
          icon: Icon(Icons.timer),
          label: 'Hours',
        ),
      if (_visibleItems.contains('finance'))
        const NavigationDestination(
          icon: Icon(Icons.attach_money),
          label: 'Finance',
        ),
      if (_visibleItems.contains('reports'))
        const NavigationDestination(
          icon: Icon(Icons.summarize),
          label: 'Reports',
        ),
      if (_visibleItems.contains('reimbursement'))
        const NavigationDestination(
          icon: Icon(Icons.receipt),
          label: 'Receipts',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
