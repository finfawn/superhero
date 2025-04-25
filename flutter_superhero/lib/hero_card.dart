class HeroCard {
  final String id;
  final String name;
  final String imageUrl;
  final Map<String, dynamic> powerstats;
  final Map<String, dynamic> biography;
  final String alignmentEmoji;

  HeroCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.powerstats,
    required this.biography,
    required this.alignmentEmoji,
  });

  factory HeroCard.fromJson(Map<String, dynamic> json) {
    return HeroCard(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Hero',
      imageUrl: json['imageUrl'] ?? json['image']?['url'] ?? '',
      powerstats: Map<String, dynamic>.from(json['powerstats'] ?? {}),
      biography: Map<String, dynamic>.from(json['biography'] ?? {}),
      alignmentEmoji: json['alignmentEmoji'] ?? '❓',
    );
  }

  int get totalPower {
    int sum = 0;
    powerstats.forEach((key, value) {
      if (value is int) sum += value;
      if (value is String) sum += int.tryParse(value) ?? 0;
    });
    return sum;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'powerstats': powerstats,
    'biography': biography,
    'alignmentEmoji': alignmentEmoji,
  };
}