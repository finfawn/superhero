// search_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_drawer.dart';
import 'superhero_service.dart';
import 'hero_card.dart';
import 'bookmark_page.dart';

class SearchPage extends StatefulWidget {
  final String apiToken;

  const SearchPage({super.key, required this.apiToken});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<HeroCard> _searchResults = [];
  bool _loading = false;
  late final SuperheroService _service;
  static const String _bookmarksKey = 'bookmarked_heroes';

  @override
  void initState() {
    super.initState();
    _service = SuperheroService(widget.apiToken);
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

  Future<void> _searchHeroes() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _searchResults.clear();
      _loading = true;
    });

    try {
      final ids = await _service.searchSuperheroes(_searchController.text);
      final results = <HeroCard>[];

      for (var id in ids) {
        final hero = await _service.fetchSuperhero(int.parse(id));
        if (hero != null && _hasValidData(hero)) {
          results.add(hero);
        }
      }

      if (mounted) {
        setState(() {
          _searchResults.addAll(results);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching heroes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasValidData(HeroCard hero) {
    if (hero.imageUrl.isEmpty || !hero.imageUrl.startsWith('http')) {
      return false;
    }

    return hero.powerstats.values.any((value) {
      if (value is int) return value > 0;
      if (value is String) return (int.tryParse(value) ?? 0) > 0;
      return false;
    });
  }

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

  Future<void> _toggleBookmark(HeroCard hero) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    final heroJson = jsonEncode(hero.toJson());

    final isBookmarked = bookmarkedHeroes.any(
      (h) => jsonDecode(h)['id'] == hero.id,
    );

    setState(() {
      if (isBookmarked) {
        bookmarkedHeroes.removeWhere((h) => jsonDecode(h)['id'] == hero.id);
      } else {
        bookmarkedHeroes.add(heroJson);
      }
    });

    await prefs.setStringList(_bookmarksKey, bookmarkedHeroes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBookmarked
              ? 'Hero removed from bookmarks'
              : 'Hero added to bookmarks',
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _isBookmarked(HeroCard hero) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    return bookmarkedHeroes.any((h) => jsonDecode(h)['id'] == hero.id);
  }

  void _showHeroDetails(HeroCard hero) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HeroDetailsModal(
        hero: hero,
        apiToken: widget.apiToken,
        onBookmarkRemoved: () {
          setState(() {}); // Refresh the UI if bookmark is removed
        },
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

    return FutureBuilder<bool>(
      future: _isBookmarked(hero),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;

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

                  // Bookmark button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Colors.amber : Colors.white,
                        size: 30,
                      ),
                      onPressed: () => _toggleBookmark(hero),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        title: const Text('Search Heroes'),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a superhero...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchHeroes,
                  ),
                ),
                onSubmitted: (_) => _searchHeroes(),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 0.5,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildHeroCard(_searchResults[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}