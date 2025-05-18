import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AuthForm extends StatefulWidget {
  final bool initialIsSignUp;
  final VoidCallback? onAuthSuccess;

  const AuthForm({
    super.key,
    this.initialIsSignUp = false,
    this.onAuthSuccess,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await AuthService().signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await AuthService().signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      widget.onAuthSuccess?.call();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome',
            style: AppTheme.headingStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing),
          Text(
            _isSignUp ? 'Create an account' : 'Sign in to continue',
            style: AppTheme.subheadingStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.largeSpacing),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (value) {
              // Trim whitespace as user types
              if (value != value.trim()) {
                final trimmed = value.trim();
                _emailController.value = TextEditingValue(
                  text: trimmed,
                  selection: TextSelection.collapsed(offset: trimmed.length),
                );
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              final trimmed = value.trim();
              if (trimmed.isEmpty) {
                return 'Please enter your email';
              }
              // Basic email validation regex
              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(trimmed)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: AppTheme.spacing),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (_isSignUp && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          if (_isSignUp) ...[
            SizedBox(height: AppTheme.spacing),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
          if (_errorMessage != null) ...[
            SizedBox(height: AppTheme.spacing),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: AppTheme.largeSpacing),
          FilledButton(
            style: AppTheme.baseButtonStyle,
            onPressed: _isLoading ? null : _handleAuth,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
          ),
          SizedBox(height: AppTheme.spacing),
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
                _errorMessage = null;
                if (!_isSignUp) {
                  _confirmPasswordController.clear();
                }
              });
            },
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : 'Need an account? Sign Up',
            ),
          ),
        ],
      ),
    );
  }
} 