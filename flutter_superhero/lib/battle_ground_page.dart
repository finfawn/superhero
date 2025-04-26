import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'hero_card.dart';
import 'widgets/app_drawer.dart';
import 'superhero_service.dart';

class BattlegroundPage extends StatefulWidget {
  final List<HeroCard> playerDeck;
  final List<HeroCard> computerDeck;
  final String apiToken;

  const BattlegroundPage({
    super.key,
    required this.playerDeck,
    required this.computerDeck,
    required this.apiToken,
  });

  @override
  State<BattlegroundPage> createState() => _BattlegroundPageState();
}

class DiceWidget extends StatelessWidget {
  final int value;
  final double size;
  final bool isRolling;

  const DiceWidget({
    super.key, 
    required this.value, 
    this.size = 60,
    this.isRolling = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isRolling ? 20 : 10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: isRolling ? 10 : 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: isRolling ? 1.2 : 1.0,
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlegroundPageState extends State<BattlegroundPage>
    with SingleTickerProviderStateMixin {
  late List<HeroCard> _playerDeck;
  late List<HeroCard> _computerDeck;
  HeroCard? _playerCard;
  HeroCard? _computerCard;
  String _roundResult = '';
  bool _playerTurn = true;
  bool _loading = false;
  bool _showFront = false;
  bool _showBattleResult = false;
  bool _gameOver = false;
  int? _diceRoll;
  int _remainingCards = 731;
  List<int> _usedHeroIds = [];
  late ConfettiController _confettiController;
  bool _showDiceResult = false;
  bool _showDeckDrawer = false;
  bool _showDiceRollModal = false;
  int _diceAnimationValue = 1;
  bool _isDiceRolling = false;
  bool _showDiceResultModal = false;
  String _diceResultMessage = '';

  late AnimationController _controller;
  late Animation<double> _animation;
  late SuperheroService _service;

  @override
  void initState() {
    super.initState();
    _playerDeck = List.from(widget.playerDeck)..shuffle();
    _computerDeck = List.from(widget.computerDeck)..shuffle();
    _service = SuperheroService(widget.apiToken);
    _usedHeroIds.addAll(_playerDeck.map((e) => int.parse(e.id)));
    _usedHeroIds.addAll(_computerDeck.map((e) => int.parse(e.id)));
    _remainingCards -= _usedHeroIds.length;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50.0),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  int _calculateTotalPower(HeroCard hero) {
    return hero.powerstats.values.fold(0, (sum, value) {
      if (value is int) return sum + value;
      if (value is String) return sum + (int.tryParse(value) ?? 0);
      return sum;
    });
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Future<void> _playTurn(int index) async {
    if (!_playerTurn || _loading || index >= _playerDeck.length) return;

    setState(() {
      _loading = true;
      _playerCard = _playerDeck[index];
      _playerDeck.removeAt(index);
      _computerCard =
          _computerDeck.isNotEmpty ? _computerDeck.removeLast() : null;
      _showFront = false;
      _roundResult = '';
      _showBattleResult = false;
      _showDiceResult = false;
      _showDeckDrawer = false;
      _showDiceRollModal = false; // Add this
      _isDiceRolling = false; // Add this
    });

    await _controller.forward(from: 0);
    setState(() => _showFront = true);

    if (_computerCard == null) {
      setState(() {
        _roundResult = 'Computer has no cards left! You win!';
        _loading = false;
        _gameOver = true;
      });
      return;
    }

    int playerPower = _calculateTotalPower(_playerCard!);
    int computerPower = _calculateTotalPower(_computerCard!);

    setState(() {
      if (playerPower > computerPower) {
        _roundResult = '🔥 You win this round!';
        _confettiController.play();
      } else if (playerPower < computerPower) {
        _roundResult = '💀 Computer wins this round!';
      } else {
        _roundResult = '⚔️ It\'s a tie!';
      }
      _showBattleResult = true;
    });

    // Show dice roll and draw cards for winner
    await Future.delayed(const Duration(seconds: 2));
    if (playerPower != computerPower) {
      await _rollDiceAndDrawCards(playerPower > computerPower);
    }

    // Reset for next turn
    setState(() {
      _playerTurn = true;
      _loading = false;
    });
  }

  Future<void> _rollDiceAndDrawCards(bool isPlayerWinner) async {
    if (isPlayerWinner) {
      // Show modal for player to roll dice
      setState(() {
        _showDiceRollModal = true;
        _isDiceRolling = false;
        _diceAnimationValue = 1;
      });
    } else {
      // Computer rolls automatically
      final random = Random();
      _diceRoll = random.nextInt(6) + 1;
      _showDiceResult = true;

      await Future.delayed(const Duration(seconds: 1));
      await _drawCardsForWinner(isPlayerWinner, _diceRoll!);
    }
  }

  Future<void> _playerRollDice() async {
    setState(() {
      _isDiceRolling = true;
      _showDiceRollModal = false;
    });

    final random = Random();

    // Animate dice rolling with more visual feedback
    for (int i = 0; i < 15; i++) {
      // Increased from 10 to 15 for longer animation
      if (!mounted) return;
      setState(() {
        _diceAnimationValue = random.nextInt(6) + 1;
      });
      await Future.delayed(
        Duration(milliseconds: 100 + (i * 10)),
      ); // Slowing down
    }

    // Final dice value
    _diceRoll = random.nextInt(6) + 1;
    setState(() {
      _diceAnimationValue = _diceRoll!;
      _diceResultMessage =
          'You rolled a $_diceRoll!\nYou receive $_diceRoll new cards!';
      _showDiceResultModal = true;
    });

    await Future.delayed(
      const Duration(seconds: 2),
    ); // Show result for 2 seconds

    setState(() {
      _showDiceResultModal = false;
    });

    await _drawCardsForWinner(true, _diceRoll!);
  }

  Future<void> _drawCardsForWinner(bool isPlayerWinner, int count) async {
    try {
      List<HeroCard> newCards = [];
      int attempts = 0;
      const maxAttempts = 20;

      while (newCards.length < count &&
          attempts < maxAttempts &&
          _remainingCards > 0) {
        attempts++;
        final randomId = Random().nextInt(731) + 1;
        if (!_usedHeroIds.contains(randomId)) {
          final hero = await _service.fetchSuperhero(randomId);
          if (hero != null) {
            newCards.add(hero);
            _usedHeroIds.add(randomId);
          }
        }
      }

      if (newCards.isNotEmpty) {
        setState(() {
          if (isPlayerWinner) {
            _playerDeck.addAll(newCards);
          } else {
            _computerDeck.addAll(newCards);
          }
          _remainingCards -= newCards.length;
          _loading = false;
          _showDiceResult = false;
        });
      } else {
        setState(() {
          _loading = false;
          _showDiceResult = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _showDiceResult = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error drawing new cards: $e')));
    }
    setState(() {
      _showDiceResult = true;
      _diceResultMessage = 'Added $_diceRoll new cards to your deck!';
    });

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _showDiceResult = false;
    });
  }

  Widget _buildPowerStatRow(String label, dynamic value) {
    final numValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                numValue.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: numValue / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              numValue > 70
                  ? Colors.greenAccent
                  : numValue > 40
                  ? Colors.orangeAccent
                  : Colors.redAccent,
            ),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(HeroCard hero, {required bool isPlayer}) {
    final color = isPlayer ? Colors.cyan.shade700 : Colors.pink.shade700;
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image with placeholder
            hero.imageUrl.isNotEmpty
                ? Image.network(
                  hero.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                )
                : _buildPlaceholderImage(),

            // Dark overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hero Name at top
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    hero.name,
                    style: GoogleFonts.bangers(
                      fontSize: 22,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Power Stats at bottom
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Power: ${_calculateTotalPower(hero)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...hero.powerstats.entries.map(
                        (e) => _buildPowerStatRow(e.key, e.value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleCard(HeroCard? hero, {required bool isPlayer}) {
    final teamColor = isPlayer ? Colors.cyan : Colors.pink;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_animation.value * 3.141592),
          alignment: Alignment.center,
          child:
              _showFront && hero != null
                  ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: teamColor.withOpacity(0.8),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: teamColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _buildHeroCard(hero, isPlayer: isPlayer),
                  )
                  : Container(
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: teamColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield,
                          size: 60,
                          color: teamColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPlayer ? 'YOUR HERO' : 'OPPONENT',
                          style: GoogleFonts.bangers(
                            fontSize: 16,
                            color: teamColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildDeckCard(HeroCard hero) {
    final totalPower = _calculateTotalPower(hero);
    return GestureDetector(
      onTap: () => _playTurn(_playerDeck.indexOf(hero)),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.shade700.withOpacity(0.8),
              Colors.blue.shade900.withOpacity(0.8),
            ],
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image with placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  hero.imageUrl.isNotEmpty
                      ? Image.network(
                        hero.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                      : _buildPlaceholderImage(),
            ),

            // Dark overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        hero.name,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Power: $totalPower',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameOver = _playerDeck.isEmpty || _computerDeck.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: Text(
          "⚔️ Superhero Battle",
          style: GoogleFonts.bangers(
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
      drawer: AppDrawer(apiToken: widget.apiToken),
      backgroundColor: Colors.deepPurple.shade900,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Round result and dice display at top
                Column(
                  children: [
                    if (_roundResult.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _roundResult,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bangers(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                // Deck counters and remaining cards
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Deck: ${_playerDeck.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Remaining Heroes: $_remainingCards',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Opponent: ${_computerDeck.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Battle area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: _buildBattleCard(
                                _computerCard,
                                isPlayer: false,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Center(
                            child: Text(
                              'VS',
                              style: GoogleFonts.bangers(
                                fontSize: 24,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: _buildBattleCard(
                                _playerCard,
                                isPlayer: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Deck drawer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Deck toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDeckDrawer = !_showDeckDrawer;
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade700,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showDeckDrawer
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Your Deck (${_playerDeck.length})',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Deck drawer content
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height:
                        _showDeckDrawer
                            ? MediaQuery.of(context).size.height * 0.5
                            : 0,
                    width: MediaQuery.of(context).size.width * 0.6, // 60% width
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade800,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: GridView.builder(
                        padding: EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 0.7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _playerDeck.length,
                        itemBuilder: (context, index) {
                          return _buildDeckCard(_playerDeck[index]);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confetti
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),

            if (_showDiceResultModal)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade800.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DICE RESULT',
                        style: GoogleFonts.bangers(
                          fontSize: 28,
                          color: Colors.amber,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform:
                            Matrix4.identity()
                              ..scale(_isDiceRolling ? 1.1 : 1.0),
                        child: DiceWidget(
                          value: _diceAnimationValue,
                          size: 120,
                          isRolling: _isDiceRolling,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _diceResultMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isDiceRolling)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showDiceResultModal = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            // Dice Roll Modal
            if (_showDiceRollModal)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade800.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ROLL FOR NEW CARDS!',
                        style: GoogleFonts.bangers(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DiceWidget(value: _diceAnimationValue, size: 100),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isDiceRolling ? null : _playerRollDice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          _isDiceRolling ? 'ROLLING...' : 'ROLL DICE',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (gameOver)
              Center(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _playerDeck.isEmpty
                            ? "💀 You ran out of cards!"
                            : "🎉 You defeated the opponent!",
                        style: GoogleFonts.bangers(
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BattlegroundPage(
                                      playerDeck: List.from(widget.playerDeck)
                                        ..shuffle(),
                                      computerDeck: List.from(
                                        widget.computerDeck,
                                      )..shuffle(),
                                      apiToken: widget.apiToken,
                                    ),
                              ),
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "PLAY AGAIN",
                          style: GoogleFonts.bangers(
                            color: Colors.deepPurple,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
