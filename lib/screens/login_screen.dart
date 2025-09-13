import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/screens/signup_screen.dart';
import 'package:moegyi/widgets/auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String email;
      final input = _emailOrUsernameController.text.trim();
      final password = _passwordController.text;

      // Check if input is an email or a username
      if (input.contains('@')) {
        // Input is likely an email
        email = input;
      } else {
        // Input is a username, so we need to find the corresponding email
        final usersQuery = await FirebaseFirestore.instance
            .collection(usersCollectionPath)
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (usersQuery.docs.isNotEmpty) {
          email = usersQuery.docs.first.data()['email'];
        } else {
          throw FirebaseAuthException(
              code: 'user-not-found', message: 'No user found for that username.');
        }
      }

      // Sign in with the resolved email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An unknown error occurred.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/login.png',
                  height: 150,
                ),
                const SizedBox(height: 24),
                Text(
                  'မင်္ဂလာပါ!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.pink),
                  
                ),
                Text(
                  'မိုးကြီးမှကြိုဆိုပါတယ်',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.pink),
                  
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.pink),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailOrUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: Colors.pink)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign Up', style: TextStyle(color: Colors.pink)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
