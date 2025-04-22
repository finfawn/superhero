import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const SuperheroGameApp());
}

class SuperheroGameApp extends StatelessWidget {
  const SuperheroGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superhero Card Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
