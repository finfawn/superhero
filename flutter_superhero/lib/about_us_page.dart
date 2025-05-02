import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'superhero_service.dart';
import 'widgets/app_drawer.dart';

class AboutUsPage extends StatefulWidget {
  final String apiToken;

  const AboutUsPage({super.key, required this.apiToken});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  late SuperheroService _service;

  @override
  void initState() {
    super.initState();
    _service = SuperheroService(widget.apiToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder:
              (BuildContext context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        centerTitle: true,
        title: const Text('About Us'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showExitConfirmation,
          ),
        ],
      ),
      drawer: AppDrawer(apiToken: widget.apiToken),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              _buildGameDescription(),
              _buildGameInstructions(),
              _buildGameMechanics(),
              _buildTeamTitle(),
              _buildTeamGrid(),
              _buildTechStack(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation() async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
  );

  if (shouldExit ?? false) {
    SystemNavigator.pop();
  }
}


  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.shade50,
            child: Icon(
              Icons.sports_kabaddi,
              size: 64,
              color: Colors.deepPurple.shade400,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SUPERHERO CARD GAME',
          style: GoogleFonts.bangers(
            fontSize: 32,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.deepPurple.shade900,
                offset: const Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Version 1.1.0',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGameDescription() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Collect, battle and explore your favorite superheroes in this exciting card game!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureChip('⚡ Epic Battles'),
                  _buildFeatureChip('🎮 Card Collection'),
                  _buildFeatureChip('🦸‍♂️ Superheroes'),
                  _buildFeatureChip('🏆 Daily Challenges'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 8,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW TO PLAY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildMechanicItem(
                '1️⃣ Select',
                'Choose a hero from your deck to battle',
              ),
              _buildMechanicItem(
                '2️⃣ Battle',
                'Your hero faces off against a random opponent hero',
              ),
              _buildMechanicItem(
                '3️⃣ Compare',
                'System compares total power stats of both heroes',
              ),
              _buildMechanicItem(
                '4️⃣ Win/Lose',
                'Hero with higher total power wins the round',
              ),
              _buildMechanicItem(
                '5️⃣ Reward',
                'Winner rolls a die and draws new cards',
              ),
              _buildMechanicItem(
                '🏆 Victory',
                'Game ends when a player loses all their cards - last player standing wins!',
              ),
              const SizedBox(height: 8),
              Text(
                '/n'
                '             Tip: Focus on building a balanced deck with heroes of different power types!             ',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.deepPurple.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameMechanics() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAME MECHANICS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildMechanicItem(
                '🎲 Dice Rolls',
                'Winner rolls a 6-sided die to determine how many new cards they draw',
              ),
              _buildMechanicItem(
                '🃏 Card Stats',
                'Each hero has 6 power stats (Intelligence, Strength, Speed, Durability, Power, Combat)',
              ),
              _buildMechanicItem(
                '⚔️ Total Power',
                'Sum of all power stats determines battle outcome',
              ),
              _buildMechanicItem(
                '🏁 Game End',
                'Game ends when a player runs out of cards in their deck',
              ),
              _buildMechanicItem(
                '🔄 Card Pool',
                '731 unique superheroes available to collect',
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Ties result in no cards being drawn for either player',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.deepPurple.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamTitle() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'GROUP MEMBERS',
        style: GoogleFonts.bangers(
          fontSize: 28,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTeamGrid() {
    return Center(
      child: SizedBox(
        height: 300,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            _buildTeamMemberCard(
              name: 'Jhemar Anablon',
              heroId: 100,
              stats: {
                'Intelligence': 0,
                'Strength': 1,
                'Speed': 1,
                'Durability': 1,
                'Power': 1,
                'Combat': 1,
              },
              color: Colors.deepPurple,
              cardWidth: 200,
            ),
            const SizedBox(width: 16),
            _buildTeamMemberCard(
              name: 'Jezreel Douglas',
              heroId: 567,
              stats: {
                'Intelligence': 100,
                'Strength': 100,
                'Speed': 100,
                'Durability': 100,
                'Power': 100,
                'Combat': 100,
              },
              color: Colors.red,
              cardWidth: 200,
            ),
            const SizedBox(width: 16),
            _buildTeamMemberCard(
              name: 'Ezekiel Palitogen Jr.',
              heroId: 472,
              stats: {
                'Intelligence': 95,
                'Strength': 85,
                'Speed': 60,
                'Durability': 85,
                'Power': 100,
                'Combat': 65,
              },
              color: Colors.orange,
              cardWidth: 200,
            ),
            const SizedBox(width: 16),
            _buildTeamMemberCard(
              name: 'John Rendell Bacasen',
              heroId: 700,
              stats: {
                'Intelligence': 90,
                'Strength': 80,
                'Speed': 70,
                'Durability': 75,
                'Power': 85,
                'Combat': 95,
              },
              color: Colors.blue,
              cardWidth: 200,
            ),
            const SizedBox(width: 16),
            _buildTeamMemberCard(
              name: 'Brenelyn Marcos',
              heroId: 400,
              stats: {
                'Intelligence': 85,
                'Strength': 75,
                'Speed': 80,
                'Durability': 70,
                'Power': 95,
                'Combat': 80,
              },
              color: Colors.purple,
              cardWidth: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStack() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'POWERED BY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildTechChip('Flutter'),
                  _buildTechChip('SuperheroAPI'),
                  _buildTechChip('Google Fonts'),
                  _buildTechChip('Dart'),
                  _buildTechChip('Shared Preferences'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard({
    required String name,
    required int heroId,
    required Map<String, int> stats,
    required Color color,
    double cardWidth = 200,
  }) {
    final totalPower = stats.values.fold(0, (sum, value) => sum + value);

    return FutureBuilder<String?>(
      future: _getHeroImageUrl(heroId, widget.apiToken),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data ?? '';

        return SizedBox(
          width: cardWidth,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _buildPlaceholderImage(),
                        )
                        : _buildPlaceholderImage(),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            name,
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
                                'Total Power: $totalPower',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...stats.entries.map(
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
            ),
          ),
        );
      },
    );
  }

  Future<String?> _getHeroImageUrl(int heroId, String apiToken) async {
    try {
      final response = await SuperheroService(apiToken).fetchSuperhero(heroId);
      return response?.imageUrl;
    } catch (e) {
      return '';
    }
  }

  Widget _buildPowerStatRow(String statName, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              statName,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
            ),
          ),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepPurple.shade300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.deepPurple.shade400,
      elevation: 3,
      shadowColor: Colors.deepPurple.shade800,
    );
  }

  Widget _buildTechChip(String label) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.deepPurple.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 3,
      shadowColor: Colors.deepPurple.shade200,
    );
  }

  Widget _buildInstructionStep(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicItem(String prefix, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$prefix ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _buildPlaceholderImage extends StatelessWidget {
  const _buildPlaceholderImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 50),
      ),
    );
  }
}
