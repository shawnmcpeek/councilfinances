import 'package:flutter/material.dart';

class AppNavigation {
  static List<NavigationRailDestination> railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.attach_money),
      label: Text('Finance'),
    ),
  ];

  static List<NavigationDestination> navigationDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.attach_money),
      label: 'Finance',
    ),
  ];
} 