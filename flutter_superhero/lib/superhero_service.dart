// superhero_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'hero_card.dart';

class SuperheroService {
  final String apiToken;
  final Random _random = Random();
  final Map<int, HeroCard> _cache = {}; // Add cache

  SuperheroService(this.apiToken) {
    if (apiToken.isEmpty) {
      throw ArgumentError('API token cannot be empty');
    }
  }

  Future<HeroCard?> fetchSuperhero(int id) async {
    final url = 'https://superheroapi.com/api/$apiToken/$id';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HeroCard.fromJson(data);
      }
    } catch (e) {
      print('Error fetching superhero: $e');
    }
    return null;
  }

  Future<HeroCard> fetchHeroById(int id) async {
    // Check cache first
    if (_cache.containsKey(id)) return _cache[id]!;

    try {
      final url = Uri.parse('https://superheroapi.com/api/$apiToken/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for API error response
        if (data['response'] == 'error') {
          throw Exception(data['error']);
        }

        // Create and cache the hero
        final hero = HeroCard.fromJson(data);
        _cache[id] = hero;
        return hero;
      } else {
        throw Exception('Failed to fetch hero: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching hero $id: $e');
    }
  }


  Future<Map<String, dynamic>> fetchHeroDetails(int id, String endpoint) async {
    final url = 'https://superheroapi.com/api/$apiToken/$id/$endpoint';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['response'] == 'error') {
          throw Exception(data['error']);
        }

        return data;
      } else {
        throw Exception(
          'Failed to fetch hero details: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error while fetching hero details: $e');
    }
  }

  Future<List<HeroCard>> getRandomHeroes(int count) async {
    if (count <= 0) throw ArgumentError('Count must be greater than 0');

    final Set<int> uniqueIds = {};
    final List<HeroCard> heroes = [];
    int attempts = 0;
    var maxAttempts = count * 2; // Allow some room for failures

    while (heroes.length < count && attempts < maxAttempts) {
      attempts++;
      final id = _random.nextInt(731) + 1;

      if (uniqueIds.contains(id)) continue;
      uniqueIds.add(id);

      try {
        final hero = await fetchHeroById(id);
        heroes.add(hero);
      } catch (e) {
        print('Failed to fetch hero $id: $e');
        // Continue trying other IDs
      }
    }

    if (heroes.isEmpty) {
      throw Exception('Failed to fetch any heroes after $maxAttempts attempts');
    }

    if (heroes.length < count) {
      print(
        'Warning: Only fetched ${heroes.length} heroes out of $count requested',
      );
    }

    return heroes;
  }

  // Add method to clear cache if needed
  void clearCache() {
    _cache.clear();
  }

  Future<List<String>> searchSuperheroes(String query) async {
    if (query.isEmpty) return [];

    final url = 'https://superheroapi.com/api/$apiToken/search/$query';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['response'] == 'error') {
          throw Exception(data['error']);
        }

        if (data['results'] == null) {
          return [];
        }

        final results = List<Map<String, dynamic>>.from(data['results']);
        return results.map((hero) => hero['id'].toString()).toList();
      } else {
        throw Exception('Failed to search heroes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching heroes: $e');
      throw Exception('Network error while searching heroes');
    }
  }
}
