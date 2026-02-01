import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(bool) onPasswordFocus;
  final Function(double) onTextChange;
  final VoidCallback? onSubmit;

  LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onPasswordFocus,
    required this.onTextChange,
    this.onSubmit,
  });

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (val) => onTextChange(val.length * 2),
        ),

        const SizedBox(height: 16),

        Focus(
          onFocusChange: onPasswordFocus,
          child: TextField(
            controller: passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              onSubmit?.call();
            },
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ),
      ],
    );
  }
}
