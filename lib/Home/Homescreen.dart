import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String fullName = "User";

  String profileImageUrl = '';
  List<String> ongoing = [];
  List<String> completed = [];
  List<Map<String, dynamic>> allModules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      fetchUserData(),
      fetchModules(),
      fetchOngoingModules(),
      fetchCompletedModules(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          String firstName = userDoc['firstName'] ?? 'First';
          String lastName = userDoc['lastName'] ?? 'Name';
          String userid = userDoc['username'] ?? 'UserName';
          fullName = "$firstName $lastName";
          userName = userid;
          profileImageUrl = userDoc['photoUrl'] ?? '';
        });
      }
    } catch (e) {
      print("User fetch error: $e");
    }
  }

  Future<void> fetchModules() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('module').get();

      setState(() {
        allModules =
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                "title": data['title'] ?? '',
                "lessons": "${data['lessons'] ?? 0} Lessons",
                "duration": data['duration'] ?? '',
                "image": data['imageUrl'] ?? 'assets/images/ob_img3.png',
                "lessonsStatus": data['lessonsStatus'] ?? [],
              };
            }).toList();
      });
    } catch (e) {
      print("Module fetch error: $e");
    }
  }

  Future<void> fetchOngoingModules() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot query =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('ongoingModules')
              .get();
      setState(() {
        ongoing = query.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      print("Ongoing fetch error: $e");
    }
  }

  Future<void> fetchCompletedModules() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot query =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('completedModules')
              .get();
      setState(() {
        completed = query.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      print("Completed fetch error: $e");
    }
  }

  // Calculate the lesson completion progress for the module
  double calculateLessonProgress(String moduleTitle) {
    int totalLessons = 0;
    int completedLessons = 0;

    allModules.forEach((module) {
      if (module['title'] == moduleTitle) {
        totalLessons = module['lessonsStatus'].length;
        completedLessons =
            module['lessonsStatus']
                .where((lessonStatus) => lessonStatus['isCompleted'] == true)
                .length;
      }
    });

    if (totalLessons == 0) return 0.0;

    return completedLessons / totalLessons;
  }

  Widget _buildLessonList(
    List<Map<String, dynamic>> modules, {
    IconData? actionIcon,
    Color? iconColor,
    Function(String)? onTap,
  }) {
    if (modules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 50,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No modules available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: modules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final module = modules[index];
        double lessonProgress = calculateLessonProgress(module['title']);

        return GestureDetector(
          onTap: () async {
            if (onTap != null) {
              onTap(module['title']);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.grey.shade200,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        module['image'],
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book,
                                size: 14,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                module['lessons'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.timer,
                                size: 14,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                module['duration'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (actionIcon != null)
                      Icon(
                        actionIcon,
                        color: iconColor ?? Colors.grey,
                        size: 28,
                      ),
                  ],
                ),
                if (lessonProgress > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: lessonProgress,
                            backgroundColor: Colors.grey[200],
                            color:
                                lessonProgress == 1.0
                                    ? Colors.green
                                    : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(lessonProgress * 100).toInt()}%",
                        style: TextStyle(
                          color:
                              lessonProgress == 1.0
                                  ? Colors.green
                                  : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/splashscreen_img_1.png',
                            height: 100,
                          ),
                          Row(
                            children: [
                              Text(
                                'Welcome 👋',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      profileImageUrl.isNotEmpty
                                          ? NetworkImage(profileImageUrl)
                                          : const AssetImage(
                                                'assets/HomeScreen_Profile.png',
                                              )
                                              as ImageProvider,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Banner Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/HomeScreen_banner.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mastery Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffA8E8F9),
                              Colors.blue.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Overall Mastery",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Unlock your greatness",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${((completed.length / (allModules.isNotEmpty ? allModules.length : 1)) * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                minHeight: 10,
                                value:
                                    completed.length /
                                    (allModules.isNotEmpty
                                        ? allModules.length
                                        : 1),
                                backgroundColor: Colors.white.withOpacity(0.5),
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tab section
                      Row(
                        children: [
                          const Text(
                            "Let's Start",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              "${completed.length}/${allModules.length} completed",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorColor: Colors.transparent,
                          labelColor: Colors.red.shade900,
                          unselectedLabelColor: Colors.grey.shade700,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: "Modules"),
                            Tab(text: "Ongoing"),
                            Tab(text: "Completed"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tab view
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLessonList(
                              allModules,
                              onTap: (title) {
                                widget.onModuleTap(title);
                              },
                            ),
                            // In TabBarView > children:
                            _buildLessonList(
                              allModules
                                  .where(
                                    (module) =>
                                        ongoing.contains(module['title']),
                                  )
                                  .toList(),
                              actionIcon: Icons.play_circle_fill,
                              iconColor: Colors.orange,
                              onTap: (title) {
                                widget.onModuleTap(title);
                              },
                            ),
                            _buildLessonList(
                              allModules
                                  .where(
                                    (module) =>
                                        completed.contains(module['title']),
                                  )
                                  .toList(),
                              actionIcon: Icons.check_circle,
                              iconColor: Colors.green,
                              onTap: (title) {
                                widget.onModuleTap(title);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
