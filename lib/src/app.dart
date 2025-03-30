import 'package:flutter/material.dart';


class MyApp extends StatefulWidget {
  final int initialIndex;
  
  const MyApp({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
          const HomeScreen(),
          const ProgramsScreen(),
          ProfileScreen(
            onProgramsPressed: () => _onItemTapped(1), // Navigate to Programs tab
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Programs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation of HomeScreen
    return Container();
  }
}

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation of ProgramsScreen
    return Container();
  }
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback onProgramsPressed;

  const ProfileScreen({
    Key? key,
    required this.onProgramsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation of ProfileScreen
    return Container();
  }
} 