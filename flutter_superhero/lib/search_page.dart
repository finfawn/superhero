// search_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_drawer.dart';
import 'superhero_service.dart';
import 'hero_card.dart';

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
    // Check if hero has valid image and at least one non-zero powerstat
    if (hero.imageUrl.isEmpty || !hero.imageUrl.startsWith('http')) {
      return false;
    }
    
    return hero.powerstats.values.any((value) {
      if (value is int) return value > 0;
      if (value is String) return (int.tryParse(value) ?? 0) > 0;
      return false;
    });
  }

  Future<void> _toggleBookmark(HeroCard hero) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    final heroJson = jsonEncode(hero.toJson());
    
    final isBookmarked = bookmarkedHeroes.any((h) => jsonDecode(h)['id'] == hero.id);
    
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
        content: Text(isBookmarked 
            ? 'Hero removed from bookmarks' 
            : 'Hero added to bookmarks'),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
      builder: (context) => HeroDetailsModal(hero: hero, apiToken: widget.apiToken),
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
              numValue > 70 ? Colors.greenAccent :
              numValue > 40 ? Colors.orangeAccent : Colors.redAccent,
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
                )
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
                            ...hero.powerstats.entries
                                .take(3)
                                .map((e) => _buildPowerStatRow(e.key, e.value)),
                          ],
                        ),
                      ),
                    ],
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

class HeroDetailsModal extends StatefulWidget {
  final HeroCard hero;
  final String apiToken;

  const HeroDetailsModal({
    super.key,
    required this.hero,
    required this.apiToken,
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
      final bio = await _service.fetchHeroDetails(widget.hero.id as int, 'biography');
      final appearance = await _service.fetchHeroDetails(widget.hero.id as int, 'appearance');
      final work = await _service.fetchHeroDetails(widget.hero.id as int, 'work');
      final connections = await _service.fetchHeroDetails(widget.hero.id as int, 'connections');
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load details: $e')),
        );
      }
    }
  }

  Future<void> _checkIfBookmarked() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    setState(() {
      _isBookmarked = bookmarkedHeroes.any((h) => jsonDecode(h)['id'] == widget.hero.id);
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    final heroJson = jsonEncode(widget.hero.toJson());
    
    setState(() {
      if (_isBookmarked) {
        bookmarkedHeroes.removeWhere((h) => jsonDecode(h)['id'] == widget.hero.id);
      } else {
        bookmarkedHeroes.add(heroJson);
      }
      _isBookmarked = !_isBookmarked;
    });
    
    await prefs.setStringList(_bookmarksKey, bookmarkedHeroes);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked 
            ? 'Hero added to bookmarks' 
            : 'Hero removed from bookmarks'),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String? value) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox();
    
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
          Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        ...data.entries.map((e) => _buildDetailItem(
          e.key.replaceAll('-', ' ').toUpperCase(),
          e.value?.toString(),
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
                Text(
                  widget.hero.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
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
                    errorBuilder: (_, __, ___) => const Icon(
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
            const Text(
              'POWER STATS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.hero.powerstats.entries.map((e) {
              final value = e.value is int ? e.value : int.tryParse(e.value.toString()) ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(value.toString()),
                    ],
                  ),
                  LinearProgressIndicator(
                    value: value / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      value > 70 ? Colors.green :
                      value > 40 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
            const SizedBox(height: 16),
            
            // Additional Details
            if (_loadingDetails)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildSection('BIOGRAPHY', _biographyDetails),
              _buildSection('APPEARANCE', _appearanceDetails),
              _buildSection('WORK', _workDetails),
              _buildSection('CONNECTIONS', _connectionsDetails),
            ],
            
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}