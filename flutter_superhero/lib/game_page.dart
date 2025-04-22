// game_page.dart
import 'package:flutter/material.dart';
import 'superhero_service.dart';
import 'battle_ground_page.dart';

class GamePage extends StatefulWidget {
  final String apiToken;

  const GamePage({
    super.key, 
    required this.apiToken
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final SuperheroService _superheroService;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _superheroService = SuperheroService(widget.apiToken);
    _setupGame();
  }

  Future<void> _setupGame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final playerDeck = await _superheroService.getRandomHeroes(5);
      final computerDeck = await _superheroService.getRandomHeroes(5);

      if (!mounted) return;

      if (playerDeck.isEmpty || computerDeck.isEmpty) {
        throw Exception('Failed to load enough heroes');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BattlegroundPage(
            playerDeck: playerDeck,
            computerDeck: computerDeck,
            apiToken: widget.apiToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load heroes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preparing Battle'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
          ),
        ),
        child: Center(
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _setupGame,
                      child: const Text('Try Again'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}