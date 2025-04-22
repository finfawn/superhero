// hero_of_the_day_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'superhero_service.dart';
import 'widgets/app_drawer.dart';

class HeroOfTheDayPage extends StatefulWidget {
  final String apiToken;

  const HeroOfTheDayPage({super.key, required this.apiToken});

  @override
  State<HeroOfTheDayPage> createState() => _HeroOfTheDayPageState();
}

class _HeroOfTheDayPageState extends State<HeroOfTheDayPage> {
  late SuperheroService _service;
  dynamic _hero;
  bool _loading = true;
  bool _isBookmarked = false;
  static const String _bookmarksKey = 'bookmarked_heroes';

  @override
  void initState() {
    super.initState();
    _service = SuperheroService(widget.apiToken);
    _fetchRandomHero();
    _checkIfBookmarked();
  }

  Future<void> _fetchRandomHero() async {
    try {
      final randomId = (1 + (DateTime.now().millisecondsSinceEpoch % 731));
      final hero = await _service.fetchSuperhero(randomId);

      setState(() {
        _hero = hero;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _toggleBookmark() async {
  if (!mounted) return; // Early return if widget is disposed
  
  final prefs = await SharedPreferences.getInstance();
  final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
  
  setState(() {
    _isBookmarked = !_isBookmarked;
    if (_isBookmarked) {
      bookmarkedHeroes.add(jsonEncode(_hero.toJson()));
    } else {
      bookmarkedHeroes.removeWhere(
        (hero) => jsonDecode(hero)['id'] == _hero.id
      );
    }
  });
  
  await prefs.setStringList(_bookmarksKey, bookmarkedHeroes);
  
  if (!mounted) return; // Check again before showing snackbar
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        _isBookmarked 
            ? 'Hero added to bookmarks' 
            : 'Hero removed from bookmarks'
      ),
      backgroundColor: Colors.deepPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

  void _checkIfBookmarked() async {
  final prefs = await SharedPreferences.getInstance();
  final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
  
  if (!mounted) return; // Check if widget is still mounted
  
  setState(() {
    _isBookmarked = bookmarkedHeroes.any(
      (hero) => jsonDecode(hero)['id'] == _hero.id
    );
  });
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
        title: const Text('Hero of the Day'),
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _hero == null
                ? const Center(
                    child: Text(
                      'Failed to load hero',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 350,
                            ),
                            child: Card(
                              elevation: 15,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.deepPurple.shade300,
                                  width: 2,
                                ),
                              ),
                              margin: const EdgeInsets.all(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                  ),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Image section
                                      Expanded(
                                        flex: 2,
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(14),
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.deepPurple.shade100,
                                                      Colors.purple.shade50,
                                                    ],
                                                  ),
                                                ),
                                                child: Image.network(
                                                  _hero.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            // Bookmark button
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    _isBookmarked
                                                        ? Icons.bookmark
                                                        : Icons.bookmark_border,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: _toggleBookmark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Details section with enhanced styling
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: Colors.deepPurple,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _hero.name,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (_hero.biography['full-name'] != '')
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      _hero.biography['full-name'],
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'Biography:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Publisher: ${_hero.biography['publisher'] ?? 'Unknown'}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                Text(
                                                  'First Appearance: ${_hero.biography['first-appearance'] ?? 'Unknown'}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                Text(
                                                  'Alignment: ${_hero.biography['alignment']?.toUpperCase() ?? 'Unknown'}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'Power Stats:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                ..._hero.powerstats.entries.map((entry) {
                                                  final value = entry.value is int
                                                      ? entry.value
                                                      : int.tryParse(entry.value.toString()) ?? 0;
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              entry.key.toUpperCase(),
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              value.toString(),
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        LinearProgressIndicator(
                                                          value: value / 100,
                                                          backgroundColor: Colors.grey[200],
                                                          valueColor: AlwaysStoppedAnimation<Color>(
                                                            value > 70
                                                                ? Colors.green
                                                                : value > 40
                                                                    ? Colors.orange
                                                                    : Colors.red,
                                                          ),
                                                          minHeight: 6,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}