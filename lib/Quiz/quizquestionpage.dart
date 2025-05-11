import 'package:design_thinking/Home/Account/Certificate.dart';
import 'package:design_thinking/Home/Account/Quiz.dart';
import 'package:design_thinking/Home/Home.dart';
import 'package:design_thinking/Home/Play.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class QuizQuestionPage extends StatefulWidget {
  final String lessonTitle;
  final int lessonIndex;
  final Function(bool) onQuizComplete;

  const QuizQuestionPage({
    super.key,
    required this.lessonTitle,
    required this.lessonIndex,
    required this.onQuizComplete,
  });

  @override
  State<QuizQuestionPage> createState() => _QuizQuestionPageState();
}

class _QuizQuestionPageState extends State<QuizQuestionPage> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool quizCompleted = false;
  int? selectedAnswerIndex;
  bool isLoading = true;
  List<Map<String, dynamic>> questions = [];
  String? errorMessage;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // Define passing threshold (70%)
  final double passingThreshold = 0.7;
  String? moduleName;

  @override
  void initState() {
    super.initState();
    print("QuizQuestionPage initialized for: '${widget.lessonTitle}'");
    print("Title length: ${widget.lessonTitle.length}");
    print("Title characters: ${widget.lessonTitle.codeUnits}");
    // Try to load from Firebase
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print("Fetching quizzes for module with title: '${widget.lessonTitle}'");
      
      // Try to find a module document that has the matching title field
      final QuerySnapshot moduleSnapshot = await FirebaseFirestore.instance
          .collection('module')
          .where('title', isEqualTo: widget.lessonTitle)
          .limit(1)
          .get();
      
      print("Found ${moduleSnapshot.docs.length} modules with title '${widget.lessonTitle}'");
      
      if (moduleSnapshot.docs.isEmpty) {
        print("No module found with title '${widget.lessonTitle}', trying direct document ID");
        
        // Fallback to using the title as the document ID
        final String docId = widget.lessonTitle;
        
        // Check if the document exists
        final DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('module')
            .doc(docId)
            .get();
        
        if (!docSnapshot.exists) {
          print("No module document found with ID: $docId");
          setState(() {
            errorMessage = null;
            isLoading = false;
            questions = [];
          });
          return;
        }
        
        // Document exists, try to get quizzes
        final QuerySnapshot quizSnapshot = await FirebaseFirestore.instance
            .collection('module')
            .doc(docId)
            .collection('quizzes')
            .get();
        
        print("Found ${quizSnapshot.docs.length} quizzes for document ID: $docId");
        _processQuizDocuments(quizSnapshot.docs);
      } else {
        // Found a module with the matching title, get its document ID
        final DocumentSnapshot moduleDoc = moduleSnapshot.docs.first;
        final String moduleId = moduleDoc.id;
        print("Found module with ID: $moduleId");
        
        // Get quizzes from this module
        final QuerySnapshot quizSnapshot = await FirebaseFirestore.instance
            .collection('module')
            .doc(moduleId)
            .collection('quizzes')
            .get();
        
        print("Found ${quizSnapshot.docs.length} quizzes for module ID: $moduleId");
        _processQuizDocuments(quizSnapshot.docs);
      }
    } catch (e) {
      print("Error fetching quizzes: ${e.toString()}");
      setState(() {
        errorMessage = null;
        isLoading = false;
        questions = [];
      });
    }
  }
  
  void _processQuizDocuments(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      setState(() {
        errorMessage = null;
        isLoading = false;
        questions = [];
      });
      return;
    }
    
    // Parse the quiz questions
    List<Map<String, dynamic>> fetchedQuestions = [];
    
    for (var doc in docs) {
      print("Processing quiz document: ${doc.id}");
      final data = doc.data() as Map<String, dynamic>;
      
      // Extract data based on the structure from Firebase
      if (data.containsKey('question') && data.containsKey('options') && data.containsKey('correctAnswer')) {
        // Get the options - they can be stored as a map or a list
        List<dynamic> options = [];
        
        if (data['options'] is List) {
          options = data['options'];
        } else if (data['options'] is Map) {
          final Map<String, dynamic> optionsMap = data['options'] as Map<String, dynamic>;
          
          // Sort the keys numerically if possible
          final List<String> sortedKeys = optionsMap.keys.toList()
            ..sort((a, b) => int.tryParse(a) != null && int.tryParse(b) != null 
                ? int.parse(a).compareTo(int.parse(b)) 
                : a.compareTo(b));
          
          for (var key in sortedKeys) {
            options.add(optionsMap[key]);
          }
        }
        
        // Parse the correct answer index
        int answerIndex;
        try {
          answerIndex = int.parse(data['correctAnswer'].toString());
        } catch (e) {
          print("Error parsing correctAnswer: ${e.toString()}, defaulting to 0");
          answerIndex = 0;
        }
        
        if (options.isNotEmpty) {
          fetchedQuestions.add({
            'question': data['question'],
            'options': options,
            'answerIndex': answerIndex,
          });
        }
      }
    }
    
    if (fetchedQuestions.isEmpty) {
      setState(() {
        errorMessage = null;
        isLoading = false;
        questions = [];
      });
      return;
    }
    
    // Shuffle all questions
    fetchedQuestions.shuffle(Random());
    
    setState(() {
      questions = fetchedQuestions;
      isLoading = false;
    });
    
    print("Successfully loaded ${questions.length} quiz questions");
  }

  void _nextQuestion() {
    if (selectedAnswerIndex != null) {
      if (selectedAnswerIndex ==
          questions[currentQuestionIndex]["answerIndex"]) {
        score++;
      }
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedAnswerIndex = null;
        });
      }
    }
  }

  Future<void> _saveQuizScore() async {
    try {
      if (currentUser == null) {
        print("Warning: Cannot save quiz score - user is not logged in");
        return;
      }
      
      print("Saving quiz score for module: ${widget.lessonTitle}");
      final double percentage = (score / questions.length) * 100;
      final bool passedQuiz = (score / questions.length) >= passingThreshold;
      
      // Save quiz score to the user's document
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid);
      
      // First check if the user document exists, create if needed
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        // Create user document
        print("Creating new user document for ${currentUser!.email}");
        await userRef.set({
          'email': currentUser!.email,
          'displayName': currentUser!.displayName,
          'lastActive': FieldValue.serverTimestamp(),
          'completedModulesCount': 0,  // Initialize with zero
        });
      }
      
      // Add the quiz score to the user's quiz_scores subcollection
      final scoreDoc = await userRef
          .collection('quiz_scores')
          .add({
        'moduleTitle': widget.lessonTitle,
        'lessonTitle': widget.lessonTitle,
        'lessonIndex': widget.lessonIndex,
        'score': score,
        'totalQuestions': questions.length,
        'percentage': percentage,
        'passed': passedQuiz,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print("Saved quiz score with ID: ${scoreDoc.id} (Score: $score/${questions.length}, Passed: $passedQuiz)");
      
      // If passed, update module completion status and unlock certificate
      if (passedQuiz) {
        await _updateModuleCompletionStatus();
      } else {
        print("Quiz not passed. Threshold: ${passingThreshold * 100}%, Score: ${percentage.toStringAsFixed(1)}%");
      }
    } catch (e) {
      print("Error saving quiz score: ${e.toString()}");
      // Add stack trace for better debugging
      print(StackTrace.current);
    }
  }
  
  Future<void> _updateModuleCompletionStatus() async {
    if (currentUser == null) {
      print("Warning: Cannot update module status - user is not logged in");
      return;
    }
    
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid);
      
      String docId = widget.lessonTitle.replaceAll(' ', '_');
      print("Updating completion status for module: ${widget.lessonTitle} (docId: $docId)");
      
      // Update module completion status with both name and title fields for compatibility
      await userRef
          .collection('completedModules')
          .doc(docId)
          .set({
        'title': widget.lessonTitle,
        'name': widget.lessonTitle,  // Add name field for compatibility with other code
        'completedAt': FieldValue.serverTimestamp(),
        'score': score,
        'totalQuestions': questions.length,
        'percentage': (score / questions.length) * 100,
      });
      
      // Unlock certificate by adding it to user's certificates collection
      await userRef
          .collection('certificates')
          .doc(docId)
          .set({
        'title': "Certificate of Completion: ${widget.lessonTitle}",
        'moduleTitle': widget.lessonTitle,
        'earnedAt': FieldValue.serverTimestamp(),
        'score': score,
        'totalQuestions': questions.length,
        'percentage': (score / questions.length) * 100,
      });
      
      print("Module marked as completed and certificate unlocked");
      
      // Also update the user's progress count
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final int completedCount = userData['completedModulesCount'] ?? 0;
        
        await userRef.update({
          'completedModulesCount': completedCount + 1,
          'lastCompletedModule': widget.lessonTitle,
          'lastCompletedAt': FieldValue.serverTimestamp(),
        });
        
        print("Updated user progress count to ${completedCount + 1}");
      }
    } catch (e) {
      print("Error updating module completion status: ${e.toString()}");
    }
  }

  void _submitQuiz() async {
    if (selectedAnswerIndex != null) {
      if (selectedAnswerIndex ==
          questions[currentQuestionIndex]["answerIndex"]) {
        score++;
      }
      
      // Save score to Firebase
      await _saveQuizScore();
      
      final bool passedQuiz = (score / questions.length) >= passingThreshold;
      
      setState(() {
        quizCompleted = true;
      });

      // Notify parent about quiz completion
      widget.onQuizComplete(passedQuiz);
    }
  }

  void _reattemptQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      quizCompleted = false;
      selectedAnswerIndex = null;
    });
    
    // Shuffle questions for each attempt
    questions.shuffle(Random());
  }

  // Method to navigate back to home and ensure data is refreshed
  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Home(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLastQuestion = currentQuestionIndex == questions.length - 1;
    bool isFirstQuestion = currentQuestionIndex == 0;
    
    // Calculate if quiz is passed
    bool isPassed = quizCompleted && ((score / questions.length) >= passingThreshold);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        elevation: 0,
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading && errorMessage == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "${currentQuestionIndex + 1}/${questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const CircularProgressIndicator()
              : errorMessage != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _fetchQuizzes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _goToHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Return to Home"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Firebase Path Information:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Module Name: ${widget.lessonTitle}"),
                              Text("Document ID: What_is_Emphathize"),
                              Text("Expected Path: modules/What_is_Emphathize/quizzes"),
                            ],
                          ),
                        ),
                      ],
                    )
                  : quizCompleted
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Quiz Completed!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Your Score: $score / ${questions.length}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                            const SizedBox(height: 10),
                            Text(
                              "Percentage: ${((score / questions.length) * 100).toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? Colors.green : Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isPassed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isPassed ? Colors.green : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isPassed
                                    ? "Congratulations! You've passed this module quiz."
                                    : "You need 70% or higher to pass this quiz.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isPassed ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _reattemptQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "Reattempt Quiz",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                         
                          ElevatedButton.icon(
                            onPressed: _goToHome,
                            icon: const Icon(Icons.home, color: Colors.white),
                            label: const Text(
                              "Go to Home",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                        )
                      : questions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.quiz_outlined,
                                    size: 70,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "No quiz questions available",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Please check back later",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: _goToHome,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    child: const Text("Return to Home"),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Question ${currentQuestionIndex + 1}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          questions[currentQuestionIndex]["question"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: List.generate(
                          questions[currentQuestionIndex]["options"].length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: selectedAnswerIndex == index
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedAnswerIndex == index
                                  ? Colors.blue
                                  : Colors.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: RadioListTile<int>(
                              title: Text(
                                questions[currentQuestionIndex]["options"][index],
                                style: TextStyle(
                                  fontWeight: selectedAnswerIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                  color: selectedAnswerIndex == index
                                    ? Colors.blue.shade800
                                    : Colors.black87,
                                ),
                              ),
                              value: index,
                              groupValue: selectedAnswerIndex,
                              onChanged: (value) {
                                setState(() {
                                  selectedAnswerIndex = value;
                                });
                              },
                              activeColor: Colors.blue,
                              selected: selectedAnswerIndex == index,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isFirstQuestion)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestionIndex--;
                                  selectedAnswerIndex = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Previous",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            const SizedBox(width: 100),
                          if (!isLastQuestion)
                            ElevatedButton(
                                        onPressed: selectedAnswerIndex != null ? _nextQuestion : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedAnswerIndex != null
                                        ? Colors.blue
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                                        onPressed: selectedAnswerIndex != null ? _submitQuiz : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedAnswerIndex != null
                                        ? Colors.green
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Submit",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
