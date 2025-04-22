import 'package:flutter/material.dart';
import 'hero_of_the_day_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  String? _error;

  void _submitToken() {
    final token = _controller.text.trim();
    if (token.isEmpty) {
      setState(() => _error = "Please enter your API token.");
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HeroOfTheDayPage(apiToken: token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter your Superhero API token:"),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'API Token',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitToken,
              child: const Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }
}
