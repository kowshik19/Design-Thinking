import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onModuleTap;
  const HomeScreen({super.key, required this.onModuleTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Client client = Client();
  late Databases databases;
  late TabController _tabController;

  List<String> module = [
    "Flutter Basics",
    "Dart Fundamentals",
    "State Management",
    "Navigation & Routing",
    "UI Components",
    "Animations",
    "Networking & API Calls",
    "Firebase Integration",
  ];
  List<String> ongoing = [];
  List<String> completed = [];

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
    fetchOngoingModules();

    // Initialize TabController with 3 tabs
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the TabController
    super.dispose();
  }

  void _initializeAppwrite() {
    client
        .setEndpoint(
          'https://cloud.appwrite.io/v1',
        ) // Replace with your endpoint
        .setProject('67d037a100204739d319'); // Replace with your project ID

    databases = Databases(client);
  }

  Future<void> fetchOngoingModules() async {
    try {
      final response = await databases.listDocuments(
        databaseId: '67d04ae6000e6892010c', // Replace with your database ID
        collectionId: '67d04af400016ead69d3', // Replace with your collection ID
      );

      setState(() {
        ongoing =
            response.documents
                .map((doc) => doc.data['name'].toString())
                .toList();
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> addToOngoing(String moduleName) async {
    try {
      await databases.createDocument(
        databaseId: '67d04ae6000e6892010c',
        collectionId: '67d04af400016ead69d3',
        documentId: ID.unique(),
        data: {'name': moduleName},
      );
      fetchOngoingModules(); // Refresh the list
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
                        'Hi, Amar 👋',
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
                controller:
                    _tabController, // Using manually controlled TabController
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
                controller: _tabController, // Manually controlled TabController
                children: [
                  ListView.builder(
                    itemCount: module.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          module[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(Icons.play_circle, color: Colors.green),
                        onTap: () {
                          addToOngoing(module[index]);
                          widget.onModuleTap(module[index]);
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
                            onTap: () {
                              // Handle tap action for ongoing modules
                            },
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
                        onTap: () {
                          // Handle tap action for completed modules
                        },
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
