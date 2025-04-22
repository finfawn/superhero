import 'package:flutter/material.dart';
import 'package:flutter_superhero/game_page.dart';
import '../hero_of_the_day_page.dart';
import '../search_page.dart';
import '../bookmark_page.dart';
import '../about_us_page.dart';

class AppDrawer extends StatelessWidget {
  final String apiToken;

  const AppDrawer({super.key, required this.apiToken});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(
                    Icons.sports_kabaddi,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Superhero Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.star,
              title: 'Hero of the Day',
              page: HeroOfTheDayPage(apiToken: apiToken),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.sports_kabaddi,
              title: 'Battle Ground',
              page: GamePage(apiToken: apiToken), // Navigate to a game setup page first
            ),
            _buildDrawerItem(
              context,
              icon: Icons.search,
              title: 'Search',
              page: SearchPage(apiToken: apiToken),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.bookmark,
              title: 'Bookmark',
              page: BookmarkPage(apiToken: apiToken),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.info,
              title: 'About Us',
              page: AboutUsPage(apiToken: apiToken),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}