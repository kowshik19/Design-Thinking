import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onModuleTap;
  const HomeScreen({super.key, required this.onModuleTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String userName = "User";
  List<String> ongoing = [];
  List<String> completed = [];
  late bool progress = false;

  final List<Map<String, String>> allModules = [
    {
      "title": "Introduction Of Design Thinking",
      "lessons": "2 Lessons",
      "duration": "30 Min",
      "image": "assets/images/ob_img3.png",
    },
    {
      "title": "Empathize",
      "lessons": "5 Lessons",
      "duration": "1hr 20Min",
      "image": "assets/images/ob_img3.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserName();
    fetchOngoingModules();
    fetchCompletedModules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchUserName() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      setState(() {
        userName = userDoc['firstName'] ?? 'User';
      });
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  Future<void> fetchOngoingModules() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('ongoingModules')
              .get();

      setState(() {
        ongoing =
            querySnapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      print("Error fetching ongoing modules: $e");
    }
  }

  Future<void> fetchCompletedModules() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('completedModules')
              .get();

      setState(() {
        completed =
            querySnapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      print("Error fetching completed modules: $e");
    }
  }

  Future<void> addToOngoing(String moduleName) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      CollectionReference ongoingCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ongoingModules');

      QuerySnapshot existing =
          await ongoingCollection.where('name', isEqualTo: moduleName).get();

      if (existing.docs.isEmpty) {
        await ongoingCollection.add({'name': moduleName});
        fetchOngoingModules();
      }
    } catch (e) {
      print("Error adding module to ongoing: $e");
    }
  }

  Future<void> markAsCompleted(String moduleName) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      CollectionReference completedCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('completedModules');

      QuerySnapshot existing =
          await completedCollection.where('name', isEqualTo: moduleName).get();

      if (existing.docs.isEmpty) {
        await completedCollection.add({'name': moduleName});

        QuerySnapshot ongoingSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('ongoingModules')
                .where('name', isEqualTo: moduleName)
                .get();

        for (var doc in ongoingSnapshot.docs) {
          await doc.reference.delete();
        }

        fetchOngoingModules();
        fetchCompletedModules();
      }
    } catch (e) {
      print("Error marking module as completed: $e");
    }
  }

  Widget _buildLessonList(
    List<Map<String, String>> modules, {
    IconData? actionIcon,
    Color? iconColor,
    Function(String)? onTap,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: modules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final module = modules[index];
        return GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap(module['title']!);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius: 5,
                  color: Colors.grey.shade200,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(module['image']!, height: 50, width: 50),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            module['lessons'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.play_circle_fill, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            module['duration'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (actionIcon != null)
                  Icon(actionIcon, color: iconColor ?? Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/splashscreen_img_1.png',
                  height: 113,
                  width: 113,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Hi, $userName 👋',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Image.asset(
                        'assets/HomeScreen_Profile.png',
                        height: 40,
                        width: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Image.asset('assets/HomeScreen_banner.png', scale: 0.1),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Design Thinking Framework',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xffA8E8F9),
              ),
              height: 130,
              width: 333,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall Mastery',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.star, color: Colors.yellow),
                      ],
                    ),
                    const Text(
                      'Unlock your greatness',
                      style: TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      value: completed.length / 6,
                      color: const Color(0xff8DF13F),
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Let's Start",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            TabBar(
              onTap: (index) {
                setState(() {
                  progress = (index == 0);
                });
              },
              controller: _tabController,
              indicatorColor: const Color(0xffE8505B),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: "Modules"),
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // MODULES TAB
                  _buildLessonList(
                    allModules,
                    actionIcon: Icons.play_circle,
                    onTap: (title) {
                      addToOngoing(title);
                      widget.onModuleTap(title);
                    },
                  ),

                  // ONGOING TAB
                  _buildLessonList(
                    ongoing
                        .map(
                          (e) => {
                            "title": e,
                            "lessons": "",
                            "duration": "",
                            "image": "assets/images/ob_img3.png",
                          },
                        )
                        .toList(),
                    actionIcon: Icons.play_circle_fill,
                    iconColor: Colors.green,
                    onTap: (title) {
                      markAsCompleted(title);
                      widget.onModuleTap(title);
                    },
                  ),

                  // COMPLETED TAB
                  _buildLessonList(
                    completed
                        .map(
                          (e) => {
                            "title": e,
                            "lessons": "",
                            "duration": "",
                            "image": "assets/images/ob_img3.png",
                          },
                        )
                        .toList(),
                    actionIcon: Icons.check_circle,
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
