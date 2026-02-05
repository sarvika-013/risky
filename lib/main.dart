import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/home_screen.dart';
import 'auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jxhyryktmhzfrtroggbf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4aHlyeWt0bWh6ZnJ0cm9nZ2JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMDA1MTEsImV4cCI6MjA4MDY3NjUxMX0.4f3Myd6yDGY7-gL81QTmL_qnU8asE72XImITASrFi4M',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // ✅ auth decides screen
    );
  }
}
