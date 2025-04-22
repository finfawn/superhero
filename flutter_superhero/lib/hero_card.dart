class HeroCard {
  final int id;
  final String name;
  final String imageUrl;
  final Map<String, dynamic> powerstats;
  final Map<String, dynamic> biography;

  HeroCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.powerstats,
    required this.biography,
  });

  factory HeroCard.fromJson(Map<String, dynamic> json) {
    return HeroCard(
      id: int.parse(json['id']),
      name: json['name'],
      imageUrl: json['image']['url'],
      powerstats: json['powerstats'],
      biography: json['biography'],
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

  int getPowerStat(String stat) {
    final value = powerstats[stat.toLowerCase()];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'powerstats': powerstats,
    'biography': biography,
  };

  static Future<void> random() async {}

  String get alignmentEmoji {
    switch (biography['alignment']?.toLowerCase()) {
      case 'good': return '🦸';
      case 'bad': return '🦹';
      default: return '🟰';
    }
  }

  String get publisherLogo {
    switch (biography['publisher']?.toLowerCase()) {
      case 'dc comics': return 'assets/dc_logo.png';
      case 'marvel comics': return 'assets/marvel_logo.png';
      default: return 'assets/default_logo.png';
    }
  }
}