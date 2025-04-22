// about_us_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_drawer.dart';

class AboutUsPage extends StatelessWidget {
  final String apiToken;

  const AboutUsPage({super.key, required this.apiToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text('About Us'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
      drawer: AppDrawer(apiToken: apiToken),
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
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

  Widget _buildTeamTitle() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'THE SUPER TEAM',
        style: GoogleFonts.bangers(
          fontSize: 28,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTeamGrid() {
    return SizedBox(
      height: 300, // Increased height for better card display
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const SizedBox(width: 8), // Initial padding
          _buildTeamMemberCard(
            name: 'Jhemar Anablon',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/1303.jpg',
            stats: {'Intelligence': 0, 'Strength': 1, 'Speed': 1, 'Durability': 1, 'Power': 1, 'Combat': 1},
            color: Colors.deepPurple,
            cardWidth: 200, // Wider cards
          ),
          const SizedBox(width: 16),
          _buildTeamMemberCard(
            name: 'Jezreel Douglas',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/10.jpg',
            stats: {'Intelligence': 100, 'Strength': 100, 'Speed': 100, 'Durability': 100, 'Power': 100, 'Combat': 100},
            color: Colors.red,
            cardWidth: 200,
          ),
          const SizedBox(width: 16),
          _buildTeamMemberCard(
            name: 'Ezekiel Palitogen Jr.',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/1496.jpg',
            stats: {'Intelligence': 95, 'Strength': 85, 'Speed': 60, 'Durability': 85, 'Power': 100, 'Combat': 65},
            color: Colors.orange,
            cardWidth: 200,
          ),
          const SizedBox(width: 16),
          _buildTeamMemberCard(
            name: 'John Rendell Bacasen',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/1008.jpg',
            stats: {'Intelligence': 90, 'Strength': 80, 'Speed': 70, 'Durability': 75, 'Power': 85, 'Combat': 95},
            color: Colors.blue,
            cardWidth: 200,
          ),
          const SizedBox(width: 16),
          _buildTeamMemberCard(
            name: 'Brenelyn Marcos',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/106.jpg',
            stats: {'Intelligence': 85, 'Strength': 75, 'Speed': 80, 'Durability': 70, 'Power': 95, 'Combat': 80},
            color: Colors.purple,
            cardWidth: 200,
          ),
          const SizedBox(width: 8), // Ending padding
        ],
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
    required String imageUrl,
    required Map<String, int> stats,
    required Color color,
    double cardWidth = 200,
  }) {
    final totalPower = stats.values.fold(0, (sum, value) => sum + value);
    
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
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero Image with placeholder
                imageUrl.isNotEmpty 
                    ? Image.network(
                        imageUrl,
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
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                
                // Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name at top
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
                            'Total Power: $totalPower',
                            style: GoogleFonts.poppins(
                              fontSize: 14, 
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...stats.entries.map((e) => _buildPowerStatRow(e.key, e.value)),
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

  Widget _buildPowerStatRow(String label, int value) {
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
                value.toString(),
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
            value: value / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              value > 70
                  ? Colors.greenAccent
                  : value > 40
                      ? Colors.orangeAccent
                      : Colors.redAccent,
            ),
            minHeight: 4,
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
}