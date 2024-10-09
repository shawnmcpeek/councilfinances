import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Council Finance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _loginWithGoogle() {
    // Google login action
    print('Login with Google pressed');
  }

  void _loginWithApple() {
    // Apple login action
    print('Login with Apple pressed');
  }

  void _loginWithEmail() {
    // Email/Password login action
    print('Login with Email/Password pressed');
  }

  void _signUpWithEmail() {
    // Email sign-up action
    print('Sign Up with Email pressed');
  }

  void _recoverPassword() {
    // Password recovery action
    print('Recover Password pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Council Finance:\nA Financial Management App for Councils and Organizations.",
          textAlign: TextAlign.center, // Centers the text
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _loginWithEmail,
              child: const Text("Login"),
            ),
            ElevatedButton(
              onPressed: _loginWithGoogle,
              child: const Text("Login with Google"),
            ),
            ElevatedButton(
              onPressed: _loginWithApple,
              child: const Text("Login with Apple"),
            ),
            ElevatedButton(
              onPressed: _signUpWithEmail,
              child: const Text("Sign Up with Email"),
            ),
            TextButton(
              onPressed: _recoverPassword,
              child: const Text("Recover Password"),
            ),
          ],
        ),
      ),
    );
  }
}
