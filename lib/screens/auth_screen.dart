import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/animated_avatar.dart';
import '../widgets/login_form.dart';
import '../widgets/signup_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final supabase = Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isPassword = false;
  double lookValue = 0;
  bool isLoading = false;

  Future<void> handleSignup() async {
    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // SUCCESS: user OR session returned
      if (res.user != null || res.session != null) {
        _showMessage("Account created. Please check your email to confirm.");
        return;
      }

      _showMessage("Signup failed. Please try again.");
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      // Supabase retry edge case: user already created
      if (msg.contains('already') || msg.contains('exists')) {
        _showMessage("Account created. Please check your email to confirm.");
        return;
      }

      _showMessage(e.message);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AnimatedAvatar(
                isPasswordFocused: isPassword,
                lookValue: lookValue,
                success: false,
                failure: false,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isLogin
                    ? LoginForm(
                        key: const ValueKey('login'),
                        emailController: emailController,
                        passwordController: passwordController,
                        onPasswordFocus: (v) =>
                            setState(() => isPassword = v),
                        onTextChange: (v) =>
                            setState(() => lookValue = v),
                      )
                    : SignupForm(
                        key: const ValueKey('signup'),
                        emailController: emailController,
                        passwordController: passwordController,
                        onPasswordFocus: (v) =>
                            setState(() => isPassword = v),
                        onTextChange: (v) =>
                            setState(() => lookValue = v),
                      ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : isLogin
                        ? handleLogin
                        : handleSignup,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(isLogin ? "Login" : "Sign Up"),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLogin = !isLogin;
                    isPassword = false;
                  });
                },
                child: Text(
                  isLogin
                      ? "Don’t have an account? Sign up!"
                      : "Already have an account? Login",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
