import 'package:design_thinking/Home/Account.dart';

import 'package:design_thinking/Home/Homescreen.dart';
import 'package:design_thinking/Home/Play.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  String selectedFolder = "";
  bool isLoadingModule = true;

  // Define your modules with lessons and their details
  final List<Map<String, dynamic>> allModules = [
    {
      "title": "Introduction Of Design Thinking",
      "lessons": [
        {
          'title': 'Introduction',
          'duration': '5:00',
          'description': 'An introduction to the basics of Design Thinking.',
        },
      ],
      "duration": "30 Min",
    },
    {
      "title": "Empathize",
      "lessons": [
        {
          'title': 'Introduction',
          'duration': '5:00',
          'description': 'An introduction to the basics of Design Thinking.',
        },
        {
          'title': 'What is Empathize',
          'duration': '6:30',
          'description':
              'Learn what Empathy means in the context of Design Thinking.',
        },
        {
          'title': 'Why Empathize',
          'duration': '5:00',
          'description':
              'Understand the importance of Empathy in the design process.',
        },
        {
          'title': 'How to Empathize',
          'duration': '6:30',
          'description':
              'Step-by-step guide to practicing Empathy effectively in Design Thinking.',
        },
      ],
      "duration": "45 Min",
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchLastViewedModule();
  }

  Future<void> fetchLastViewedModule() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data['lastViewedModule'] != null) {
        selectedFolder = data['lastViewedModule'];
      } else {
        selectedFolder = allModules[0]['title']; // Default to the first module
      }
    } else {
      selectedFolder =
          allModules[0]['title']; // Default if no user is signed in
    }

    setState(() => isLoadingModule = false);
  }

  Map<String, dynamic> getSelectedModule() {
    return allModules.firstWhere(
      (module) => module['title'] == selectedFolder,
      orElse: () => allModules[0], // Default to the first module
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingModule) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedModule = getSelectedModule();

    // List of pages for navigation
    final List<Widget> _pages = [
      HomeScreen(
        onModuleTap: (folder) async {
          setState(() {
            selectedFolder = folder;
            _currentIndex = 1; // Navigate to VideoPlayScreen
          });

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).set(
              {'lastViewedModule': folder},
              SetOptions(merge: true),
            ); // Merge to avoid overwriting other fields
          }
        },
      ),
      VideoPlayScreen(
        moduleName: selectedModule['title'],
        lessons: List<Map<String, dynamic>>.from(selectedModule['lessons']),
      ),
      Account(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: GNav(
          tabBorderRadius: 50,
          gap: 8,
          color: Colors.black,
          activeColor: Colors.white,
          iconSize: 0,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          tabBackgroundColor: const Color(0xff75DBCE),
          tabs: [
            GButton(
              leading: Image.asset(
                'assets/Nav/Home.png',
                width: 24,
                height: 24,
              ),
              icon: Icons.home,
            ),
            GButton(
              leading: Image.asset(
                'assets/Nav/Search.png',
                width: 24,
                height: 24,
              ),
              icon: Icons.search,
            ),
            // GButton(
            //   leading: Image.asset(
            //     'assets/Nav/Vector.png',
            //     width: 24,
            //     height: 24,
            //   ),
            //   icon: Icons.play_arrow,
            // ),
            GButton(
              leading: Image.asset(
                'assets/Nav/Profile.png',
                width: 24,
                height: 24,
              ),
              icon: Icons.person,
            ),
          ],
          selectedIndex: _currentIndex,
          onTabChange: (index) {
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }
}
