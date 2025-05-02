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
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _submitToken() async {
    final token = _controller.text.trim();
    if (token.isEmpty) {
      setState(() => _error = "Please enter your API token");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HeroOfTheDayPage(apiToken: token),
      ),
    );
  }

  

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.purple.shade800,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hero Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    size: 48,
                    color: Colors.amber,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'SUPERHERO BATTLE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Enter your API token',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 32),

                // Token Input Field (more compact)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 280, // Fixed width for better control
                  ),
                  child: TextField(
                    controller: _controller,
                    obscureText: _obscureText,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true, // Reduces vertical padding
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      labelText: 'API Token',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.vpn_key, 
                        color: Colors.white70, 
                        size: 20), // Smaller icon
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, // Reduced vertical padding
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Login Button (more compact)
                SizedBox(
                  width: 200, // Fixed width
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitToken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12, // Reduced height
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'START',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Help Text
                TextButton(
                  onPressed: () {
                    // Add link opening functionality here
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Get API token from superheroapi.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}