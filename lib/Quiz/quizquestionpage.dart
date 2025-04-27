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

  @override
  void initState() {
    super.initState();
    _fetchQuizQuestions();
  }

  Future<void> _fetchQuizQuestions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Reference to the Firestore collection containing quiz questions
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('lessonIndex', isEqualTo: widget.lessonIndex)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "No questions found for this lesson.";
          isLoading = false;
        });
        return;
      }

      // Parse the questions from Firestore
      List<Map<String, dynamic>> fetchedQuestions = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('questions')) {
          List<dynamic> questionsList = data['questions'];
          for (var question in questionsList) {
            fetchedQuestions.add(Map<String, dynamic>.from(question));
          }
        }
      }
      
      // Shuffle the questions
      fetchedQuestions.shuffle(Random());

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load questions: ${e.toString()}";
        isLoading = false;
      });
    }
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
      if (currentUser != null) {
        final double percentage = (score / questions.length) * 100;
        final bool passedQuiz = (score / questions.length) >= passingThreshold;
        
        // Save quiz score directly under user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('quiz_scores')
            .add({
          'lessonIndex': widget.lessonIndex,
          'lessonTitle': widget.lessonTitle,
          'score': score,
          'totalQuestions': questions.length,
          'percentage': percentage,
          'passed': passedQuiz,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // If passed, update module completion status
        if (passedQuiz) {
          await _updateModuleCompletionStatus();
        }
      } else {
        // Handle anonymous user or guest mode
        // Create a device-specific ID for anonymous users
        final String anonymousId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
        
        await FirebaseFirestore.instance
            .collection('anonymous_scores')
            .doc(anonymousId)
            .set({
          'lessonIndex': widget.lessonIndex,
          'lessonTitle': widget.lessonTitle,
          'score': score,
          'totalQuestions': questions.length,
          'percentage': (score / questions.length) * 100,
          'passed': (score / questions.length) >= passingThreshold,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving quiz score: ${e.toString()}");
    }
  }
  
  Future<void> _updateModuleCompletionStatus() async {
    if (currentUser == null) return;
    
    try {
      // Map module index to module ID
      final Map<int, String> moduleIds = {
        0: 'introduction',
        1: 'empathize',
        2: 'define',
        3: 'ideate',
        4: 'prototype',
        5: 'test'
      };
      
      String moduleId = moduleIds[widget.lessonIndex] ?? 'unknown';
      
      // Update module status in user's document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('moduleStatus')
          .doc(moduleId)
          .set({
        'moduleId': moduleId,
        'lessonIndex': widget.lessonIndex,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'score': score,
        'totalQuestions': questions.length,
        'percentage': (score / questions.length) * 100,
      }, SetOptions(merge: true));
      
    } catch (e) {
      print("Error updating module status: ${e.toString()}");
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
                          onPressed: _fetchQuizQuestions,
                          child: const Text("Retry"),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Return to Home"),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CertificateGenerator(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.card_membership, color: Colors.white),
                            label: const Text(
                              "View Certificates",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Home(),
                                ),
                                (route) => false,
                              );
                            },
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
                          ? const Center(
                              child: Text(
                                "No questions available for this lesson",
                                style: TextStyle(fontSize: 18),
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
                      Text(
                        questions[currentQuestionIndex]["question"],
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: List.generate(
                          questions[currentQuestionIndex]["options"].length,
                          (index) => RadioListTile<int>(
                            title: Text(
                              questions[currentQuestionIndex]["options"][index],
                            ),
                            value: index,
                            groupValue: selectedAnswerIndex,
                            onChanged: (value) {
                              setState(() {
                                selectedAnswerIndex = value;
                              });
                            },
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
