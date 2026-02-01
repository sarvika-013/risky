import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

/// Ensures a row exists in the User table for the current auth user (for username/avatar).
void ensureUserRow() {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final userId = user.id;
  final email = user.email ?? '';

  client.from('User').upsert(
    {
      'user_id': userId,
      'username': email.isNotEmpty ? email.split('@').first : 'user_${userId.substring(0, 8)}',
      'avatar_url': 'assets/images/b1.jpg',
    },
    onConflict: 'user_id',
  ).then((_) {}).catchError((_) {});
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          ensureUserRow();
          return const HomeScreen(); // ✅ logged in
        }

        return const AuthScreen(); // 🔐 not logged in
      },
    );
  }
}
