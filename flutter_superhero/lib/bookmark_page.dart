// bookmark_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_drawer.dart';
import 'hero_card.dart';
import 'superhero_service.dart';

class BookmarkPage extends StatefulWidget {
  final String apiToken;

  const BookmarkPage({super.key, required this.apiToken});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  static const String _bookmarksKey = 'bookmarked_heroes';
  late SuperheroService _service;
  List<HeroCard> _bookmarkedHeroes = [];

  @override
  void initState() {
    super.initState();
    _service = SuperheroService(widget.apiToken);
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarked = prefs.getStringList(_bookmarksKey) ?? [];

    setState(() {
      _bookmarkedHeroes =
          bookmarked
              .map((String heroJson) {
                try {
                  final Map<String, dynamic> heroMap = json.decode(heroJson);
                  return HeroCard.fromJson(heroMap);
                } catch (e) {
                  return HeroCard(
                    id: 'error',
                    name: 'Invalid Hero',
                    imageUrl: '',
                    powerstats: {},
                    biography: {},
                    alignmentEmoji: '❓',
                  );
                }
              })
              .where((hero) => hero.id.isNotEmpty)
              .toList();
    });
  }

  Future<void> _removeBookmark(HeroCard hero) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];

    bookmarkedHeroes.removeWhere((h) => jsonDecode(h)['id'] == hero.id);
    await prefs.setStringList(_bookmarksKey, bookmarkedHeroes);

    if (mounted) {
      setState(() {
        _bookmarkedHeroes.removeWhere((h) => h.id == hero.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hero removed from bookmarks'),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showHeroDetails(HeroCard hero) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => HeroDetailsModal(
            hero: hero,
            apiToken: widget.apiToken,
            onBookmarkRemoved: () => _removeBookmark(hero),
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

  Widget _buildHeroCard(HeroCard hero) {
    final totalPower = hero.powerstats.values.fold(0, (sum, value) {
      if (value is int) return sum + value;
      if (value is String) return sum + (int.tryParse(value) ?? 0);
      return sum;
    });

    return GestureDetector(
      onTap: () => _showHeroDetails(hero),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.5),
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
                  // Name at top
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
                          'Total Power: $totalPower',
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

              // Alignment indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAlignmentIcon(hero.biography['alignment']),
                    color: _getAlignmentColor(hero.biography['alignment']),
                    size: 16,
                  ),
                ),
              ),

              // Remove bookmark button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.bookmark,
                    color: Colors.amber,
                    size: 30,
                  ),
                  onPressed: () => _removeBookmark(hero),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add these helper methods to both files:
  IconData _getAlignmentIcon(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'good':
        return Icons.verified_user;
      case 'bad':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }

  Color _getAlignmentColor(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'good':
        return Colors.blue;
      case 'bad':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => SystemNavigator.pop(),
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
        child:
            _bookmarkedHeroes.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookmarked heroes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.7, // Increased from 0.5
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount:
                      _bookmarkedHeroes
                          .length, // or _searchResults.length in search_page.dart
                  itemBuilder: (context, index) {
                    return _buildHeroCard(
                      _bookmarkedHeroes[index],
                    ); // or _searchResults[index]
                  },
                ),
      ),
    );
  }
}

class HeroDetailsModal extends StatefulWidget {
  final HeroCard hero;
  final String apiToken;
  final VoidCallback? onBookmarkRemoved;

  const HeroDetailsModal({
    super.key,
    required this.hero,
    required this.apiToken,
    this.onBookmarkRemoved,
  });

  @override
  State<HeroDetailsModal> createState() => _HeroDetailsModalState();
}

class _HeroDetailsModalState extends State<HeroDetailsModal> {
  late SuperheroService _service;
  Map<String, dynamic>? _biographyDetails;
  Map<String, dynamic>? _appearanceDetails;
  Map<String, dynamic>? _workDetails;
  Map<String, dynamic>? _connectionsDetails;
  bool _loadingDetails = false;
  bool _isBookmarked = false;
  static const String _bookmarksKey = 'bookmarked_heroes';

  @override
  void initState() {
    super.initState();
    _service = SuperheroService(widget.apiToken);
    _checkIfBookmarked();
    _loadAdditionalDetails();
  }

  Future<void> _loadAdditionalDetails() async {
    setState(() => _loadingDetails = true);

    try {
      final bio = await _service.fetchHeroDetails(
        widget.hero.id as int,
        'biography',
      );
      final appearance = await _service.fetchHeroDetails(
        widget.hero.id as int,
        'appearance',
      );
      final work = await _service.fetchHeroDetails(
        widget.hero.id as int,
        'work',
      );
      final connections = await _service.fetchHeroDetails(
        widget.hero.id as int,
        'connections',
      );

      setState(() {
        _biographyDetails = bio;
        _appearanceDetails = appearance;
        _workDetails = work;
        _connectionsDetails = connections;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() => _loadingDetails = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load details: $e')));
      }
    }
  }

  Future<void> _checkIfBookmarked() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    setState(() {
      _isBookmarked = bookmarkedHeroes.any(
        (h) => jsonDecode(h)['id'] == widget.hero.id,
      );
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    final heroJson = jsonEncode(widget.hero.toJson());

    setState(() {
      if (_isBookmarked) {
        bookmarkedHeroes.removeWhere(
          (h) => jsonDecode(h)['id'] == widget.hero.id,
        );
        widget.onBookmarkRemoved?.call();
      } else {
        bookmarkedHeroes.add(heroJson);
      }
      _isBookmarked = !_isBookmarked;
    });

    await prefs.setStringList(_bookmarksKey, bookmarkedHeroes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked
              ? 'Hero added to bookmarks'
              : 'Hero removed from bookmarks',
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDetailItem(String title, String? value) {
    final displayValue = value ?? 'Unknown';
    if (displayValue.isEmpty || displayValue == 'null') return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          Text(displayValue, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    Map<String, dynamic>? data, {
    IconData? icon,
  }) {
    if (data == null || data.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.deepPurple, size: 20),
            if (icon != null) const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...data.entries.map(
          (e) => _buildDetailItem(
            e.key.replaceAll('-', ' ').toUpperCase(),
            e.value?.toString(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine alignment icon and color
    final alignment =
        widget.hero.biography['alignment']?.toString().toLowerCase() ??
        'neutral';
    IconData alignmentIcon;
    Color alignmentColor;

    switch (alignment) {
      case 'good':
        alignmentIcon = Icons.verified_user;
        alignmentColor = Colors.blue;
        break;
      case 'bad':
        alignmentIcon = Icons.dangerous;
        alignmentColor = Colors.red;
        break;
      default:
        alignmentIcon = Icons.help_outline;
        alignmentColor = Colors.grey;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and alignment
            Row(
              children: [
                Icon(alignmentIcon, color: alignmentColor, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.hero.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.amber : Colors.deepPurple,
                    size: 30,
                  ),
                  onPressed: _toggleBookmark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Image
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.hero.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.grey,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Power Stats
            _buildSection(
              'POWER STATS',
              widget.hero.powerstats,
              icon: Icons.bolt,
            ),

            // Biography
            _buildSection('BIOGRAPHY', _biographyDetails, icon: Icons.info),

            // Appearance
            _buildSection('APPEARANCE', _appearanceDetails, icon: Icons.face),

            // Work
            _buildSection('WORK', _workDetails, icon: Icons.work),

            // Connections
            _buildSection(
              'CONNECTIONS',
              _connectionsDetails,
              icon: Icons.people,
            ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
