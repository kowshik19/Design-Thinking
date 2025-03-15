import 'package:design_thinking/Home/Account.dart';
import 'package:design_thinking/Home/Homescreen.dart';
import 'package:design_thinking/Home/Play.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    VideoPlayScreen(folder: "Flutter Basics"),
    Account(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Show the selected screen
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: GNav(
          tabBorderRadius: 50,
          gap: 8, // Spacing between icon and text
          color: Colors.black, // Inactive icon color
          activeColor: Colors.white, // Active icon color
          iconSize: 0, // Hide default icon to use custom PNG
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          tabBackgroundColor: Color(
            0xff75DBCE,
          ), // Selected tab background color
          tabs: [
            GButton(
              leading: Image.asset(
                'assets/Nav/Home.png',
                width: 24,
                height: 24,
              ),
              icon: Icons.abc,
            ),
            GButton(
              leading: Image.asset(
                'assets/Nav/Search.png',
                width: 24,
                height: 24,
              ),
              // text: 'Search',
              icon: Icons.abc,
            ),

            GButton(
              leading: Image.asset(
                'assets/Nav/Profile.png',
                width: 24,
                height: 24,
              ),
              // text: 'Profile',
              icon: Icons.abc,
            ),
          ],
          selectedIndex: _currentIndex,
          onTabChange: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
