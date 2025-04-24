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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserData();
    fetchModules();
    fetchOngoingModules();
    fetchCompletedModules();
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
        child: Text(
          'No modules available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: modules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                Image.asset(module['image'], height: 50, width: 50),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              module['lessons'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.timer, size: 14),
                            Text(
                              module['duration'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
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
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/splashscreen_img_1.png', scale: 2),
                  Row(
                    children: [
                      Text(
                        'Hi, $userName 👋',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : const AssetImage(
                                      'assets/HomeScreen_Profile.png',
                                    )
                                    as ImageProvider,
                      ),
                    ],
                  ),
                ],
              ),
              Image.asset('assets/HomeScreen_banner.png'),
              const SizedBox(height: 10),
              Container(
                height: 130,
                width: 330,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xffA8E8F9),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Mastery",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Unlock your greatness",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${((completed.length / (allModules.isNotEmpty ? allModules.length : 1)) * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      minHeight: 8,
                      value:
                          completed.length /
                          (allModules.isNotEmpty ? allModules.length : 1),
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                  ],
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
                controller: _tabController,
                indicatorColor: Colors.redAccent,
                labelColor: Colors.black,
                tabs: const [
                  Tab(text: "Modules"),
                  Tab(text: "Ongoing"),
                  Tab(text: "Completed"),
                ],
              ),
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
                          .where((module) => ongoing.contains(module['title']))
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
                            (module) => completed.contains(module['title']),
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

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomeScreen extends StatefulWidget {
//   final Function(String) onModuleTap;
//   const HomeScreen({super.key, required this.onModuleTap});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String userName = "User";
//   String fullName = "User";

//   String profileImageUrl = '';
//   List<String> ongoing = [];
//   List<String> completed = [];
//   List<Map<String, dynamic>> allModules = [];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     fetchUserData();
//     fetchModules();
//     fetchOngoingModules();
//     fetchCompletedModules();
//   }

//   Future<void> fetchUserData() async {
//     try {
//       String uid = FirebaseAuth.instance.currentUser!.uid;
//       DocumentSnapshot userDoc =
//           await FirebaseFirestore.instance.collection('users').doc(uid).get();
//       if (userDoc.exists) {
//         setState(() {
//           String firstName = userDoc['firstName'] ?? 'First';
//           String lastName = userDoc['lastName'] ?? 'Name';
//           String userid = userDoc['username'] ?? 'UserName';
//           fullName = "$firstName $lastName";
//           userName = userid;
//           profileImageUrl = userDoc['photoUrl'] ?? '';
//         });
//       }
//     } catch (e) {
//       print("User fetch error: $e");
//       print(userName);
//     }
//   }

//   Future<void> fetchModules() async {
//     try {
//       QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('module').get();

//       setState(() {
//         allModules =
//             snapshot.docs.map((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               return {
//                 "title": data['title'] ?? '',
//                 "lessons": "${data['lessons'] ?? 0} Lessons",
//                 "duration": data['duration'] ?? '',
//                 "image": data['imageUrl'] ?? 'assets/images/ob_img3.png',
//               };
//             }).toList();
//       });
//     } catch (e) {
//       print("Module fetch error: $e");
//     }
//   }

//   Future<void> fetchOngoingModules() async {
//     try {
//       String uid = FirebaseAuth.instance.currentUser!.uid;
//       QuerySnapshot query =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(uid)
//               .collection('ongoingModules')
//               .get();
//       setState(() {
//         ongoing = query.docs.map((doc) => doc['name'].toString()).toList();
//       });
//     } catch (e) {
//       print("Ongoing fetch error: $e");
//     }
//   }

//   Future<void> fetchCompletedModules() async {
//     try {
//       String uid = FirebaseAuth.instance.currentUser!.uid;
//       QuerySnapshot query =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(uid)
//               .collection('completedModules')
//               .get();
//       setState(() {
//         completed = query.docs.map((doc) => doc['name'].toString()).toList();
//       });
//     } catch (e) {
//       print("Completed fetch error: $e");
//     }
//   }

//   // Future<void> addToOngoing(String title) async {
//   //   try {
//   //     String uid = FirebaseAuth.instance.currentUser!.uid;
//   //     var ongoingRef = FirebaseFirestore.instance
//   //         .collection('users')
//   //         .doc(uid)
//   //         .collection('ongoingModules');

//   //     var exists = await ongoingRef.where('name', isEqualTo: title).get();

//   //     if (exists.docs.isEmpty) {
//   //       await ongoingRef.add({'name': title});
//   //       await _saveResumePoint(title, 0);
//   //       fetchOngoingModules();
//   //     }
//   //   } catch (e) {
//   //     print("Add ongoing error: $e");
//   //   }
//   // }

//   // Future<void> markAsCompleted(String title) async {
//   //   try {
//   //     String uid = FirebaseAuth.instance.currentUser!.uid;
//   //     var completedRef = FirebaseFirestore.instance
//   //         .collection('users')
//   //         .doc(uid)
//   //         .collection('completedModules');

//   //     var exists = await completedRef.where('name', isEqualTo: title).get();

//   //     if (exists.docs.isEmpty) {
//   //       await completedRef.add({'name': title});

//   //       var ongoingDocs =
//   //           await FirebaseFirestore.instance
//   //               .collection('users')
//   //               .doc(uid)
//   //               .collection('ongoingModules')
//   //               .where('name', isEqualTo: title)
//   //               .get();

//   //       for (var doc in ongoingDocs.docs) {
//   //         await doc.reference.delete();
//   //       }

//   //       await _clearResumePoint(title);

//   //       fetchOngoingModules();
//   //       fetchCompletedModules();
//   //     }
//   //   } catch (e) {
//   //     print("Mark completed error: $e");
//   //   }
//   // }

//   // Future<void> _saveResumePoint(String module, int position) async {
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   await prefs.setInt('resume_$module', position);
//   // }

//   // Future<int> _getResumePoint(String module) async {
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   return prefs.getInt('resume_$module') ?? 0;
//   // }

//   // Future<void> _clearResumePoint(String module) async {
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   await prefs.remove('resume_$module');
//   // }

//   Widget _buildLessonList(
//     List<Map<String, dynamic>> modules, {
//     IconData? actionIcon,
//     Color? iconColor,
//     Function(String)? onTap,
//   }) {
//     if (modules.isEmpty) {
//       return Center(
//         child: Text(
//           'No modules available.',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       itemCount: modules.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 10),
//       itemBuilder: (context, index) {
//         final module = modules[index];
//         return GestureDetector(
//           onTap: () async {
//             if (onTap != null) {
//               onTap(module['title']);
//               //await addToOngoing(module['title']);
//             }
//           },
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   blurRadius: 5,
//                   color: Colors.grey.shade200,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Image.asset(module['image'], height: 50, width: 50),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         module['title'],
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Row(
//                         children: [
//                           Text(
//                             module['lessons'] ?? '',
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                           const SizedBox(width: 10),
//                           const Icon(Icons.timer, size: 14),
//                           Text(
//                             module['duration'] ?? '',
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (actionIcon != null)
//                   Icon(actionIcon, color: iconColor ?? Colors.grey),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 100,
//         title: Image.asset('assets/splashscreen_img_1.png', height: 150),
//         actions: [
//           Row(
//             children: [
//               Text(
//                 'Hi, $userName 👋',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               CircleAvatar(
//                 radius: 30,
//                 backgroundImage:
//                     profileImageUrl.isNotEmpty
//                         ? NetworkImage(profileImageUrl)
//                         : const AssetImage('assets/HomeScreen_Profile.png')
//                             as ImageProvider,
//               ),
//             ],
//           ),
//           SizedBox(width: 15),
//         ],
//         backgroundColor: Colors.white,
//       ),
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Column(
//           children: [
//             Image.asset('assets/HomeScreen_banner.png'),
//             const SizedBox(height: 10),
//             Container(
//               height: 130,
//               width: 330,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(20),
//                 color: const Color(0xffA8E8F9),
//               ),
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Overall Mastery",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const Text(
//                     "Unlock your greatness",
//                     style: TextStyle(fontSize: 12),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     '${((completed.length / (allModules.isNotEmpty ? allModules.length : 1)) * 100).toInt()}%',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   LinearProgressIndicator(
//                     minHeight: 8,
//                     value:
//                         completed.length /
//                         (allModules.isNotEmpty ? allModules.length : 1),
//                     backgroundColor: Colors.grey[300],
//                     color: Colors.green,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "Let's Start",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//             ),
//             TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.redAccent,
//               labelColor: Colors.black,
//               tabs: const [
//                 Tab(text: "Modules"),
//                 Tab(text: "Ongoing"),
//                 Tab(text: "Completed"),
//               ],
//             ),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildLessonList(
//                     allModules,
//                     onTap: (title) {
//                       widget.onModuleTap(title);
//                     },
//                   ),
//                   _buildLessonList(
//                     ongoing
//                         .map(
//                           (e) => {
//                             "title": e,
//                             "lessons": "",
//                             "duration": "",
//                             "image": "assets/images/ob_img3.png",
//                           },
//                         )
//                         .toList(),
//                     actionIcon: Icons.play_circle_fill,
//                     iconColor: Colors.orange,
//                     onTap: (title) {
//                       widget.onModuleTap(title);
//                     },
//                   ),
//                   _buildLessonList(
//                     completed
//                         .map(
//                           (e) => {
//                             "title": e,
//                             "lessons": "",
//                             "duration": "",
//                             "image": "assets/images/ob_img3.png",
//                           },
//                         )
//                         .toList(),
//                     actionIcon: Icons.check_circle,
//                     iconColor: Colors.green,
//                     onTap: (title) {
//                       widget.onModuleTap(title);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
