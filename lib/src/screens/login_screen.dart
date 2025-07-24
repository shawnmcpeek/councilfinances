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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section
              Container(
                margin: EdgeInsets.only(bottom: AppTheme.largeSpacing),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/knights1.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: AppTheme.spacing),
                    Text(
                      'Welcome to Knights Management',
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'Your tool to run your council and assembly',
                      style: AppTheme.subheadingStyle.copyWith(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Login form card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing),
                  child: const AuthForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 