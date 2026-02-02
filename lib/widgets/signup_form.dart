import 'package:flutter/material.dart';

class SignupForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(bool) onPasswordFocus;
  final Function(double) onTextChange;
  final VoidCallback? onSubmit;

  const SignupForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onPasswordFocus,
    required this.onTextChange,
    this.onSubmit,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;

  @override
  void initState() {
    super.initState();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.only(bottom: 200),
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_passwordFocus),
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (val) => widget.onTextChange(val.length * 2),
        ),

        const SizedBox(height: 12),

        Focus(
          onFocusChange: widget.onPasswordFocus,
          child: TextField(
            controller: widget.passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            scrollPadding: const EdgeInsets.only(bottom: 200),
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              widget.onSubmit?.call(); // 🔥 auto signup
            },
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ),
      ],
    );
  }
}
