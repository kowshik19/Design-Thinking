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
  List<Map<String, dynamic>> allModules = [];

  @override
  void initState() {
    super.initState();
    fetchModules().then((_) => fetchLastViewedModule());
  }

  Future<void> fetchModules() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('module').get();
    List<Map<String, dynamic>> loadedModules = [];

    for (final doc in snapshot.docs) {
      final lessonsSnapshot = await doc.reference.collection('lessons').get();

      final lessons =
          lessonsSnapshot.docs.map((lessonDoc) {
            return lessonDoc.data();
          }).toList();

      loadedModules.add({
        'title': doc['title'],
        'duration': doc['duration'],
        'imageUrl': doc['imageUrl'],
        'lessons': lessons,
      });
    }

    setState(() {
      allModules = loadedModules;
      isLoadingModule = false;
    });
  }

  Future<void> fetchLastViewedModule() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data['lastViewedModule'] != null) {
        selectedFolder = data['lastViewedModule'];
      } else if (allModules.isNotEmpty) {
        selectedFolder = allModules[0]['title'];
      }
    } else if (allModules.isNotEmpty) {
      selectedFolder = allModules[0]['title'];
    }

    setState(() => isLoadingModule = false);
  }

  Map<String, dynamic> getSelectedModule() {
    return allModules.firstWhere(
      (module) => module['title'] == selectedFolder,

      orElse: () => allModules[0],
    );
  }

  // Future<void> updateUserProgress(String moduleName, bool completed) async {
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;

  //   final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
  //   final progressCollection = userDoc.collection('progress');

  //   final existingSnapshot =
  //       await progressCollection
  //           .where('moduleName', isEqualTo: moduleName)
  //           .get();

  //   if (existingSnapshot.docs.isEmpty) {
  //     await progressCollection.add({
  //       'moduleName': moduleName,
  //       'status': completed ? 'completed' : 'ongoing',
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //   } else {
  //     final docRef = existingSnapshot.docs.first.reference;
  //     final existingStatus = existingSnapshot.docs.first.data()['status'];
  //     if (existingStatus != 'completed' && completed) {
  //       await docRef.update({
  //         'status': 'completed',
  //         'timestamp': FieldValue.serverTimestamp(),
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoadingModule) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedModule = getSelectedModule();

    final List<Widget> _pages = [
      HomeScreen(
        onModuleTap: (folder) async {
          setState(() {
            selectedFolder = folder;
            _currentIndex = 1;
          });

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'lastViewedModule': folder,
            }, SetOptions(merge: true));

            // Add to progress if not completed already
            //  await updateUserProgress(folder, false);
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
