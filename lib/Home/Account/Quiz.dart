import 'package:design_thinking/Home/Account.dart';
import 'package:design_thinking/Home/Homescreen.dart';
import 'package:design_thinking/Home/Play.dart';
import 'package:design_thinking/Quiz/quizsplash.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  int _currentIndex = 2; // Set default index to Quiz tab

  List<Map<String, dynamic>> quizzes = [];
  bool isLoading = true;
  String? errorMessage;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Fetch modules from Firebase
      final QuerySnapshot modulesSnapshot = await FirebaseFirestore.instance
          .collection('modules')
          .get();

      if (modulesSnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "No modules found.";
          isLoading = false;
        });
        return;
      }

      // Create quiz list from Firebase modules
      List<Map<String, dynamic>> fetchedQuizzes = [];
      int index = 0;
      
      // Define fallback colors in case they're not specified in Firestore
      List<Color> fallbackColors = [
        const Color(0xffE1627D),
        Colors.lightBlue,
        const Color(0xffE8505B),
        const Color(0xffFE654C),
        const Color(0xff9533AA),
        const Color(0xff19A983),
      ];

      for (var doc in modulesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Use title from Firestore, or doc.id if title is not available
        String title = data['title'] ?? doc.id;
        
        // Use image from Firestore if available, otherwise use default pattern
        String imageUrl = data['imageUrl'] ?? 'assets/quiz/q${index + 1}.jpg';
        
        // Use color from Firestore if available, otherwise use fallback colors
        Color color = index < fallbackColors.length 
            ? fallbackColors[index] 
            : Colors.grey;

        fetchedQuizzes.add({
          "id": doc.id,
          "title": title,
          "color": color,
          "image": imageUrl,
          "completed": false,
          "lessonIndex": index,
        });
        
        index++;
      }

      setState(() {
        quizzes = fetchedQuizzes;
        isLoading = false;
      });
      
      // Load progress after fetching modules
      _loadProgress();
    } catch (e) {
      print("Error fetching modules: ${e.toString()}");
      setState(() {
        errorMessage = "Failed to load modules: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Future<void> _loadProgress() async {
    try {
      // First use local SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Then check Firebase for more accurate data
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get completed modules from Firebase
        final completedModulesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('completedModules')
            .get();
            
        // Create a set of completed module titles
        Set<String> completedModuleTitles = {};
        for (var doc in completedModulesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('title')) {
            completedModuleTitles.add(data['title'].toString());
          } else if (data.containsKey('name')) {
            completedModuleTitles.add(data['name'].toString());
          }
        }
        
        // Also check quiz_scores for passed quizzes
        final quizScoresSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('quiz_scores')
            .where('passed', isEqualTo: true)
            .get();
            
        // Add passed quiz module titles to the set
        for (var doc in quizScoresSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('moduleTitle')) {
            completedModuleTitles.add(data['moduleTitle'].toString());
          }
        }
        
        // Update the quizzes list
        for (int i = 0; i < quizzes.length; i++) {
          // Check if completed in Firebase
          bool isCompletedInFirebase = completedModuleTitles.contains(quizzes[i]["title"]);
          
          // Use Firebase data preferentially, fall back to SharedPreferences
          if (isCompletedInFirebase) {
            quizzes[i]["completed"] = true;
            // Update shared preferences to match
            final String moduleId = quizzes[i]["id"];
            await prefs.setBool("quiz_$moduleId", true);
          } else {
            // If not found in Firebase, use SharedPreferences
            final String moduleId = quizzes[i]["id"];
            quizzes[i]["completed"] = prefs.getBool("quiz_$moduleId") ?? false;
          }
        }
        
        print("Loaded completion status for ${quizzes.length} quizzes, found ${completedModuleTitles.length} completed modules");
      } else {
        // If not logged in, just use SharedPreferences
        for (int i = 0; i < quizzes.length; i++) {
          final String moduleId = quizzes[i]["id"];
          quizzes[i]["completed"] = prefs.getBool("quiz_$moduleId") ?? false;
        }
      }
      
      _updateProgress();
    } catch (e) {
      print("Error loading progress: $e");
      // Fall back to just SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < quizzes.length; i++) {
        final String moduleId = quizzes[i]["id"];
        quizzes[i]["completed"] = prefs.getBool("quiz_$moduleId") ?? false;
      }
      _updateProgress();
    }
  }

  Future<void> _saveProgress(int index) async {
    try {
      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String moduleId = quizzes[index]["id"];
      await prefs.setBool("quiz_$moduleId", quizzes[index]["completed"]);
      
      // Also update Firebase if user is logged in
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && quizzes[index]["completed"]) {
        // Only update Firebase if the quiz is completed
        final String moduleTitle = quizzes[index]["title"];
        final String docId = moduleTitle.replaceAll(' ', '_');
        
        // Update completedModules collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('completedModules')
            .doc(docId)
            .set({
          'title': moduleTitle,
          'name': moduleTitle,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print("Updated completion status in Firebase for module: $moduleTitle");
      }
    } catch (e) {
      print("Error saving progress: $e");
    }
  }

  void _updateProgress() {
    int completedCount = quizzes.where((quiz) => quiz["completed"]).length;
    setState(() {
      progress = quizzes.isEmpty ? 0 : completedCount / quizzes.length;
    });
  }

  void _markQuizComplete(int index) {
    setState(() {
      quizzes[index]["completed"] = true;
      _saveProgress(index);
      _updateProgress();
    });
  }

  void _navigateToQuiz(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Quizsplash(
              lessonTitle: quizzes[index]["title"],
              lessonIndex: quizzes[index]["lessonIndex"],
              onComplete: () => _markQuizComplete(index),
            ),
      ),
    );
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigation to corresponding pages
    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(onModuleTap: (folder) {});
        break;
      case 1:
        nextPage = VideoPlayScreen(
          moduleName: "moduleName",
          lessons: [],
        ); // Adjust as needed
        break;
      case 2:
        return; // Already in Quiz page, do nothing
      case 3:
        nextPage = const Account();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quiz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_sharp),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchModules,
            tooltip: 'Refresh modules',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchModules,
                  child: const Text("Retry"),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Completed",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress, minHeight: 10),
              const SizedBox(height: 20),
              quizzes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No modules available",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                )
              : Column(
                children:
                    quizzes.asMap().entries.map((entry) {
                      int index = entry.key;
                      var quiz = entry.value;
                      return GestureDetector(
                        onTap: () => _navigateToQuiz(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: quiz["color"],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: quiz["completed"],
                                onChanged: null, // Disable manual checking
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Quiz ${index + 1}:",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      quiz['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (quiz["image"] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    quiz["image"],
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
