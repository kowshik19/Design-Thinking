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
  String userName = "User"; // Default value
  List<String> modules = [
    "What is Design Thinking",
    "Empathize",
    "Define ",
    "Ideate",
    "Prototype",
  ];
  List<String> ongoing = [];
  List<String> completed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserName();
    fetchOngoingModules();
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
        userName = userDoc['firstName'] ?? 'User'; // Ensure proper fallback
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
            querySnapshot.docs
                .map(
                  (doc) => doc['name'].toString(),
                ) // Ensure correct field name
                .toList();
      });
    } catch (e) {
      print("Error fetching ongoing modules: $e");
    }
  }

  Future<void> addToOngoing(String moduleName) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      CollectionReference ongoingCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ongoingModules');

      // Check if the module already exists
      QuerySnapshot existingModules =
          await ongoingCollection.where('name', isEqualTo: moduleName).get();

      if (existingModules.docs.isEmpty) {
        // Add only if it doesn't already exist
        await ongoingCollection.add({'name': moduleName});
        fetchOngoingModules(); // Refresh list
      } else {
        print("Module already exists in ongoing list.");
      }
    } catch (e) {
      print("Error adding module: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
                        style: TextStyle(
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
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Design Thinking Framework',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: 20),
            Image.asset('assets/HomeScreen_img1.png', scale: 0.1),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Let's Start",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Theme(
              data: ThemeData(
                tabBarTheme: TabBarTheme(dividerColor: Colors.transparent),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Color(0xffE8505B),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: "Modules"),
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          modules[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(Icons.play_circle, color: Colors.green),
                        onTap: () {
                          addToOngoing(modules[index]);
                          widget.onModuleTap(modules[index]);
                        },
                      );
                    },
                  ),
                  ongoing.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: ongoing.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              ongoing[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.play_circle,
                              color: Colors.green,
                            ),
                          );
                        },
                      ),
                  ListView.builder(
                    itemCount: completed.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          completed[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
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
