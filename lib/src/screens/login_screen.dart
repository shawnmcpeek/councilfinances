import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacing),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing),
              child: const AuthForm(),
            ),
          ),
        ),
      ),
    );
  }
} 