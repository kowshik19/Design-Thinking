import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class QuizHistory extends StatefulWidget {
  const QuizHistory({Key? key}) : super(key: key);

  @override
  State<QuizHistory> createState() => _QuizHistoryState();
}

class _QuizHistoryState extends State<QuizHistory> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  List<Map<String, dynamic>> quizScores = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuizHistory();
  }

  Future<void> _fetchQuizHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (currentUser == null) {
        setState(() {
          errorMessage = "Please log in to view your quiz history.";
          isLoading = false;
        });
        return;
      }
      
      // Query Firestore for quiz scores directly from the user's document
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('quiz_scores')
          .orderBy('timestamp', descending: true)
          .get();

      // Parse data from Firestore
      List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // First check if moduleTitle exists, and only if not, use lessonTitle or default
        String title = data['moduleTitle']?.toString() ?? 
                      data['lessonTitle']?.toString() ?? 
                      'Unknown Lesson';
        
        // Handle empty string case
        if (title.trim().isEmpty) {
          title = 'Unknown Lesson';
        }
                    
        history.add({
          'id': doc.id,
          'lessonTitle': title,
          'lessonIndex': data['lessonIndex'] ?? 0,
          'score': data['score'] ?? 0,
          'totalQuestions': data['totalQuestions'] ?? 10,
          'percentage': data['percentage'] ?? 0.0,
          'passed': data['passed'] ?? false,
          'timestamp': data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate() 
              : DateTime.now(),
        });
      }

      setState(() {
        quizScores = history;
        isLoading = false;
      });
      
      // Print for debugging
      print("Loaded ${quizScores.length} quiz records from history");
      for (var quiz in quizScores) {
        print("Quiz: ${quiz['lessonTitle']} - Score: ${quiz['score']}/${quiz['totalQuestions']}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load quiz history: ${e.toString()}";
        isLoading = false;
      });
      print("Quiz history error: $e");
      print(StackTrace.current); // Print stack trace for better debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quiz History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: isLoading
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
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchQuizHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : quizScores.isEmpty
                  ? const Center(
                      child: Text(
                        'No quiz history found.\nComplete a quiz to see your results here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Quiz Attempts',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: quizScores.length,
                              itemBuilder: (context, index) {
                                final quiz = quizScores[index];
                                final percentage = quiz['percentage'] as double;
                                final timestamp = quiz['timestamp'] as DateTime;
                                final bool passed = quiz['passed'] ?? false;
                                final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(timestamp);
                                
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: passed ? Colors.green : Colors.grey.shade300,
                                      width: passed ? 2 : 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              passed ? Icons.check_circle : Icons.info_outline,
                                              color: passed ? Colors.green : Colors.orange,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                quiz['lessonTitle'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Date: $formattedDate',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Score: ${quiz['score']}/${quiz['totalQuestions']}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: percentage >= 70
                                                    ? Colors.green
                                                    : percentage >= 50
                                                        ? Colors.orange
                                                        : Colors.red,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${percentage.toStringAsFixed(1)}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (passed)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: Colors.green.shade200),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check, color: Colors.green, size: 16),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    'Module Completed',
                                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 