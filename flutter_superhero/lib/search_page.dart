// search_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isBookmarked = false;
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
        final hero = await _service.fetchSuperhero(id as int);
        if (hero != null) {
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
          SnackBar(content: Text('Error searching heroes: $e')),
        );
      }
    }
  }

  void _toggleBookmark(HeroCard hero) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedHeroes = prefs.getStringList(_bookmarksKey) ?? [];
    
    setState(() {
      _isBookmarked = !_isBookmarked;
      if (_isBookmarked) {
        bookmarkedHeroes.add(jsonEncode(hero.toJson()));
      } else {
        bookmarkedHeroes.removeWhere(
          (h) => jsonDecode(h)['id'] == hero.id
        );
      }
    });
    
    await prefs.setStringList(_bookmarksKey, bookmarkedHeroes);
    
    if (!mounted) return;
    
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final hero = _searchResults[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
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
                                                    hero.imageUrl,
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
                                                    onPressed: () => _toggleBookmark(hero),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                                                    hero.name,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (hero.biography['full-name'] != '')
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4.0),
                                                      child: Text(
                                                        hero.biography['full-name'],
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[600],
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
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
                                                  ...hero.powerstats.entries.map((entry) {
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
                                                  }),
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
                            );
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