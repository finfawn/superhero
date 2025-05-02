// bookmark_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_drawer.dart';
import 'hero_card.dart';
import 'superhero_service.dart';

// Shared helper methods
IconData getAlignmentIcon(String? alignment) {
  switch (alignment?.toLowerCase()) {
    case 'good':
      return Icons.verified_user;
    case 'bad':
      return Icons.dangerous;
    default:
      return Icons.help_outline;
  }
}

Color getAlignmentColor(String? alignment) {
  switch (alignment?.toLowerCase()) {
    case 'good':
      return Colors.blue;
    case 'bad':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

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

  Future<void> _showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarked = prefs.getStringList(_bookmarksKey) ?? [];

    setState(() {
      _bookmarkedHeroes = bookmarked
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
      builder: (context) => HeroDetailsModal(
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
                    getAlignmentIcon(hero.biography['alignment']),
                    color: getAlignmentColor(hero.biography['alignment']),
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
        title: const Text('Bookmarks'),
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
        child: _bookmarkedHeroes.isEmpty
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
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _bookmarkedHeroes.length,
                itemBuilder: (context, index) {
                  return _buildHeroCard(_bookmarkedHeroes[index]);
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
    if (!mounted) return;

    setState(() => _loadingDetails = true);

    try {
      final heroId = int.parse(widget.hero.id);
      
      final bio = await _service.fetchHeroDetails(heroId, 'biography');
      final appearance = await _service.fetchHeroDetails(heroId, 'appearance');
      final work = await _service.fetchHeroDetails(heroId, 'work');
      final connections = await _service.fetchHeroDetails(heroId, 'connections');

      if (mounted) {
        setState(() {
          _biographyDetails = bio;
          _appearanceDetails = appearance;
          _workDetails = work;
          _connectionsDetails = connections;
          _loadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDetails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          _isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDetailCard(String title, String? value, {IconData? icon}) {
    final displayValue = value ?? 'Unknown';
    if (displayValue.isEmpty || displayValue == 'null') return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(icon, size: 20, color: Colors.deepPurple),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerStatCard(String label, dynamic value) {
    final numValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  numValue.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: numValue / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                numValue > 70
                    ? Colors.green
                    : numValue > 40
                        ? Colors.orange
                        : Colors.red,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDetail(String key) {
    switch (key.toLowerCase()) {
      case 'full-name':
        return Icons.person;
      case 'alter-egos':
        return Icons.masks;
      case 'aliases':
        return Icons.people_alt;
      case 'place-of-birth':
        return Icons.place;
      case 'first-appearance':
        return Icons.calendar_today;
      case 'publisher':
        return Icons.business;
      case 'alignment':
        return Icons.verified;
      case 'gender':
        return Icons.transgender;
      case 'race':
        return Icons.people;
      case 'height':
        return Icons.height;
      case 'weight':
        return Icons.monitor_weight;
      case 'eye-color':
        return Icons.remove_red_eye;
      case 'hair-color':
        return Icons.face_retouching_natural;
      case 'occupation':
        return Icons.work;
      case 'base':
        return Icons.home;
      case 'group-affiliation':
        return Icons.groups;
      case 'relatives':
        return Icons.family_restroom;
      default:
        return Icons.info;
    }
  }

  Widget _buildSection(String title, Map<String, dynamic>? data, {IconData? icon}) {
    if (data == null || data.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, color: Colors.deepPurple, size: 24),
              if (icon != null) const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
        if (title == 'POWER STATS')
          ...data.entries.map((e) => _buildPowerStatCard(e.key, e.value))
        else
          ...data.entries.map((e) => _buildDetailCard(
                e.key.replaceAll('-', ' '),
                e.value?.toString(),
                icon: _getIconForDetail(e.key),
              )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.hero.name,
                    style: GoogleFonts.bangers(
                      fontSize: 28,
                      color: Colors.deepPurple,
                      letterSpacing: 1.5,
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

            // Hero Image with alignment indicator
            Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.hero.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getAlignmentIcon(widget.hero.biography['alignment']),
                        color: getAlignmentColor(widget.hero.biography['alignment']),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Power Stats (always shown)
            _buildSection(
              'POWER STATS',
              widget.hero.powerstats,
              icon: Icons.bolt,
            ),

            // Loading indicator for additional details
            if (_loadingDetails)
              const Center(child: CircularProgressIndicator()),

            // Additional details (shown when loaded)
            if (_biographyDetails != null)
              _buildSection('BIOGRAPHY', _biographyDetails, icon: Icons.info),
            if (_appearanceDetails != null)
              _buildSection('APPEARANCE', _appearanceDetails, icon: Icons.face),
            if (_workDetails != null)
              _buildSection('WORK', _workDetails, icon: Icons.work),
            if (_connectionsDetails != null)
              _buildSection('CONNECTIONS', _connectionsDetails, icon: Icons.people),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'CLOSE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}