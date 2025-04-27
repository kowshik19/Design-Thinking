import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadQuizData extends StatefulWidget {
  const UploadQuizData({Key? key}) : super(key: key);

  @override
  State<UploadQuizData> createState() => _UploadQuizDataState();
}

class _UploadQuizDataState extends State<UploadQuizData> {
  bool _isUploading = false;
  String _status = 'Ready to upload';

  final Map<int, List<Map<String, dynamic>>> quizQuestions = {
    0: [
      {
        "question": "What is the first stage of the Design Thinking process?",
        "options": ["Define", "Prototype", "Empathize", "Ideate"],
        "answerIndex": 2,
      },
      {
        "question": "Which stage focuses on generating a wide range of ideas?",
        "options": ["Define", "Ideate", "Test", "Empathize"],
        "answerIndex": 1,
      },
      {
        "question": "What is the main goal of the 'Define' phase?",
        "options": [
          "Understanding user needs",
          "Framing the problem",
          "Building a prototype",
          "Testing the solution",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which method is commonly used in the 'Empathize' stage?",
        "options": ["User interviews", "A/B testing", "Prototyping", "Coding"],
        "answerIndex": 0,
      },
      {
        "question": "Why is prototyping important in Design Thinking?",
        "options": [
          "To finalize the product",
          "To gather user feedback",
          "To increase costs",
          "To skip testing",
        ],
        "answerIndex": 1,
      },
      {
        "question": "What does 'HMW' stand for in Design Thinking?",
        "options": [
          "How Many Ways",
          "High Market Worth",
          "How Might We",
          "Human Machine Workflow",
        ],
        "answerIndex": 2,
      },
      {
        "question":
            "Which of the following is NOT a principle of Design Thinking?",
        "options": [
          "Human-centered approach",
          "Iterative process",
          "Ignoring user feedback",
          "Creative problem-solving",
        ],
        "answerIndex": 2,
      },
      {
        "question":
            "Which of the following is a key outcome of the 'Test' phase?",
        "options": [
          "Final product launch",
          "User feedback for improvement",
          "Skipping unnecessary changes",
          "Immediate market release",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which company is known for promoting Design Thinking?",
        "options": ["Apple", "IDEO", "Google", "Tesla"],
        "answerIndex": 1,
      },
      {
        "question": "What is the primary purpose of Design Thinking?",
        "options": [
          "To create user-centric solutions",
          "To focus only on business goals",
          "To reduce creativity",
          "To avoid problem-solving",
        ],
        "answerIndex": 0,
      },
    ],
    1: [
      {
        "question":
            "What is the primary goal of the Empathize phase in Design Thinking?",
        "options": [
          "Generating creative ideas",
          "Understanding users and their needs",
          "Building a prototype",
          "Testing solutions",
        ],
        "answerIndex": 1,
      },
      {
        "question":
            "Which of the following techniques is commonly used in the Empathize phase?",
        "options": [
          "User interviews",
          "A/B testing",
          "Unit testing",
          "Prototyping",
        ],
        "answerIndex": 0,
      },
      {
        "question": "Why is empathy important in Design Thinking?",
        "options": [
          "It helps businesses focus only on profits",
          "It ensures decisions are made based on assumptions",
          "It helps designers understand user pain points",
          "It removes the need for testing",
        ],
        "answerIndex": 2,
      },
      {
        "question":
            "Which of the following is NOT a method used in the Empathize phase?",
        "options": [
          "Surveys",
          "Observation",
          "Storyboarding",
          "Code debugging",
        ],
        "answerIndex": 3,
      },
      {
        "question": "Which question is most relevant in the Empathize phase?",
        "options": [
          "What problem are we solving for users?",
          "How can we market this product?",
          "What technology should we use?",
          "How can we increase profits?",
        ],
        "answerIndex": 0,
      },
      {
        "question": "What is a user persona?",
        "options": [
          "A fictional character representing target users",
          "A type of design prototype",
          "A marketing strategy",
          "A code library for UX design",
        ],
        "answerIndex": 0,
      },
      {
        "question": "How do designers gain insights in the Empathize phase?",
        "options": [
          "By analyzing user behavior and emotions",
          "By skipping research and making assumptions",
          "By directly coding a solution",
          "By launching the final product first",
        ],
        "answerIndex": 0,
      },
      {
        "question": "What is an example of empathizing with users?",
        "options": [
          "Conducting interviews to understand frustrations",
          "Ignoring feedback to stick to the initial idea",
          "Prioritizing company goals over user needs",
          "Assuming all users have the same preferences",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Which of the following is a common mistake in the Empathize phase?",
        "options": [
          "Gathering diverse user insights",
          "Using multiple research techniques",
          "Making decisions based on assumptions",
          "Observing real user interactions",
        ],
        "answerIndex": 2,
      },
      {
        "question": "How does empathy drive innovation in Design Thinking?",
        "options": [
          "By forcing users to change habits",
          "By understanding real user problems and needs",
          "By eliminating creativity in problem-solving",
          "By avoiding user feedback",
        ],
        "answerIndex": 1,
      },
    ],
    2: [
      {
        "question":
            "What is the primary goal of the Define phase in Design Thinking?",
        "options": [
          "Generating a large number of ideas",
          "Understanding the user's emotions",
          "Clearly defining the problem statement",
          "Building a working prototype",
        ],
        "answerIndex": 2,
      },
      {
        "question": "What is typically created at the end of the Define phase?",
        "options": [
          "A fully developed product",
          "A problem statement",
          "A prototype for testing",
          "A marketing strategy",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which of the following best describes the Define stage?",
        "options": [
          "Observing and understanding users",
          "Generating potential solutions",
          "Refining and testing prototypes",
          "Framing the core problem to be solved",
        ],
        "answerIndex": 3,
      },
      {
        "question": "Which of these is a key outcome of the Define phase?",
        "options": [
          "A clear, actionable problem statement",
          "A detailed technical specification",
          "A finalized user interface design",
          "A completed user interview report",
        ],
        "answerIndex": 0,
      },
      {
        "question": "What is the primary input for the Define phase?",
        "options": [
          "User research data from the Empathize phase",
          "Finalized product requirements",
          "A working prototype",
          "Marketing insights",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Which of the following is a common mistake in the Define phase?",
        "options": [
          "Reframing the problem statement based on user needs",
          "Making assumptions without user research",
          "Narrowing down a problem to focus on solutions",
          "Synthesizing insights from user research",
        ],
        "answerIndex": 1,
      },
      {
        "question":
            "Which technique is often used to define the problem in this stage?",
        "options": [
          "Storyboarding",
          "Empathy mapping",
          "Problem statement formulation",
          "A/B testing",
        ],
        "answerIndex": 2,
      },
      {
        "question": "Why is defining the problem correctly important?",
        "options": [
          "It helps in identifying the right solutions",
          "It eliminates the need for ideation",
          "It speeds up the final product launch",
          "It replaces the need for user feedback",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Which of the following is NOT a characteristic of a well-defined problem statement?",
        "options": [
          "Focused on user needs",
          "Broad and vague",
          "Clear and specific",
          "Actionable",
        ],
        "answerIndex": 1,
      },
      {
        "question": "What role does user persona play in the Define phase?",
        "options": [
          "Helps in understanding user needs and challenges",
          "Eliminates the need for prototyping",
          "Ensures only technical feasibility is considered",
          "Directly replaces market research",
        ],
        "answerIndex": 0,
      },
    ],
    3: [
      {
        "question":
            "What is the primary goal of the Ideate stage in Design Thinking?",
        "options": [
          "Testing prototypes",
          "Generating a wide range of creative ideas",
          "Defining the problem statement",
          "Understanding user needs",
        ],
        "answerIndex": 1,
      },
      {
        "question":
            "Which of the following is a key activity in the Ideate stage?",
        "options": [
          "Brainstorming",
          "User interviews",
          "Market analysis",
          "Bug fixing",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Why is quantity prioritized over quality in the Ideate stage?",
        "options": [
          "To ensure more ideas are generated before filtering",
          "To finalize the best solution immediately",
          "To avoid user feedback",
          "To reduce creativity",
        ],
        "answerIndex": 0,
      },
      {
        "question": "Which technique is commonly used in the Ideate phase?",
        "options": [
          "A/B testing",
          "Storyboarding",
          "Brainwriting",
          "Debugging",
        ],
        "answerIndex": 2,
      },
      {
        "question": "What should be avoided in the Ideate stage?",
        "options": [
          "Judging ideas too early",
          "Encouraging creative thinking",
          "Collaborating with team members",
          "Exploring multiple solutions",
        ],
        "answerIndex": 0,
      },
      {
        "question": "Which of the following best describes the Ideate stage?",
        "options": [
          "Defining the user problem",
          "Generating diverse solutions",
          "Creating high-fidelity prototypes",
          "Finalizing the best solution",
        ],
        "answerIndex": 1,
      },
      {
        "question": "What is the main purpose of a brainstorming session?",
        "options": [
          "To analyze market trends",
          "To develop a final prototype",
          "To generate as many ideas as possible",
          "To test user feedback",
        ],
        "answerIndex": 2,
      },
      {
        "question": "Which mindset is most important during the Ideate phase?",
        "options": [
          "Being open to all possibilities",
          "Focusing on only one solution",
          "Avoiding risks and creativity",
          "Finalizing the product design",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Which of the following is an effective brainstorming rule?",
        "options": [
          "Criticize every idea",
          "Encourage wild ideas",
          "Focus only on one solution",
          "Reject ideas that seem impossible",
        ],
        "answerIndex": 1,
      },
      {
        "question": "What happens after the Ideate phase in Design Thinking?",
        "options": [
          "Prototyping the best ideas",
          "Repeating the Define phase",
          "Releasing the final product",
          "Conducting market analysis",
        ],
        "answerIndex": 0,
      },
    ],
    4: [
      {
        "question":
            "What is the main objective of the Prototype stage in Design Thinking?",
        "options": [
          "To create a final product",
          "To build testable representations of ideas",
          "To generate as many ideas as possible",
          "To analyze market competition",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which of the following best describes a prototype?",
        "options": [
          "A fully developed product",
          "A preliminary version of a solution",
          "A finalized UI/UX design",
          "A theoretical model of the product",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Why is prototyping important in Design Thinking?",
        "options": [
          "It allows for early testing and feedback",
          "It eliminates the need for user research",
          "It helps in finalizing the design immediately",
          "It removes the need for coding",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Which of the following is NOT a characteristic of a prototype?",
        "options": [
          "Interactive and testable",
          "A representation of an idea",
          "A final, polished product",
          "Quick and inexpensive to create",
        ],
        "answerIndex": 2,
      },
      {
        "question":
            "What type of prototype is created using paper sketches or wireframes?",
        "options": [
          "High-fidelity prototype",
          "Low-fidelity prototype",
          "Final product",
          "Digital prototype",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which tool is commonly used for digital prototyping?",
        "options": ["Adobe XD", "Notepad", "Microsoft Word", "Excel"],
        "answerIndex": 0,
      },
      {
        "question": "What is the purpose of testing prototypes?",
        "options": [
          "To finalize the product for launch",
          "To identify strengths and weaknesses of the design",
          "To bypass user feedback",
          "To develop the marketing strategy",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which of the following is a key benefit of prototyping?",
        "options": [
          "Reduces the risk of failure",
          "Eliminates the need for further testing",
          "Ensures instant market success",
          "Prevents changes in the design",
        ],
        "answerIndex": 0,
      },
      {
        "question": "What should be done after building a prototype?",
        "options": [
          "Immediately launch the product",
          "Test it with real users",
          "Discard the prototype",
          "Skip to finalizing the design",
        ],
        "answerIndex": 1,
      },
      {
        "question":
            "Which of the following is an example of a high-fidelity prototype?",
        "options": [
          "A hand-drawn wireframe",
          "A clickable digital interface",
          "A rough paper sketch",
          "A written description of an idea",
        ],
        "answerIndex": 1,
      },
    ],
    5: [
      {
        "question":
            "What is the main objective of the Test stage in Design Thinking?",
        "options": [
          "To finalize the product for launch",
          "To gather user feedback and refine the prototype",
          "To generate as many ideas as possible",
          "To define the problem statement",
        ],
        "answerIndex": 1,
      },
      {
        "question": "Which method is commonly used in the Test phase?",
        "options": [
          "A/B Testing",
          "Brainstorming",
          "Market Research",
          "Storyboarding",
        ],
        "answerIndex": 0,
      },
      {
        "question": "Why is the Test stage important in Design Thinking?",
        "options": [
          "It helps validate the prototype with real users",
          "It eliminates the need for future improvements",
          "It ensures the product is complete and final",
          "It replaces the need for prototyping",
        ],
        "answerIndex": 0,
      },
      {
        "question": "What should be done if a prototype fails during testing?",
        "options": [
          "Launch it anyway",
          "Iterate and refine based on feedback",
          "Abandon the project",
          "Ignore the test results",
        ],
        "answerIndex": 1,
      },
      {
        "question":
            "Which of the following is NOT a best practice in the Test stage?",
        "options": [
          "Gathering unbiased user feedback",
          "Observing users interact with the prototype",
          "Assuming all users will behave the same way",
          "Making changes based on test insights",
        ],
        "answerIndex": 2,
      },
      {
        "question": "Who should ideally test the prototype?",
        "options": [
          "Only the design team",
          "End users and stakeholders",
          "Developers only",
          "Marketing team",
        ],
        "answerIndex": 1,
      },
      {
        "question": "What should be the focus when analyzing test results?",
        "options": [
          "Understanding user pain points and improving design",
          "Proving that the design is perfect",
          "Avoiding all future iterations",
          "Convincing users that the design is correct",
        ],
        "answerIndex": 0,
      },
      {
        "question":
            "Which type of feedback is most valuable in the Test phase?",
        "options": [
          "Constructive criticism from real users",
          "Only positive feedback",
          "Assumptions made by the design team",
          "Random opinions from unrelated users",
        ],
        "answerIndex": 0,
      },
      {
        "question": "How can usability testing improve the final product?",
        "options": [
          "By identifying design flaws early",
          "By skipping user validation",
          "By reducing user involvement",
          "By focusing only on aesthetics",
        ],
        "answerIndex": 0,
      },
      {
        "question": "What is a key outcome of the Test phase?",
        "options": [
          "A finalized, market-ready product",
          "Insights for improving the prototype",
          "Elimination of all user testing",
          "A completed business strategy",
        ],
        "answerIndex": 1,
      },
    ],
  };

  final Map<int, String> lessonTitles = {
    0: "Introduction to Design Thinking",
    1: "Empathize",
    2: "Define",
    3: "Ideate",
    4: "Prototype",
    5: "Test"
  };

  Future<void> _uploadQuizData() async {
    setState(() {
      _isUploading = true;
      _status = 'Uploading...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Loop through each lesson index and upload data
      for (final entry in quizQuestions.entries) {
        final lessonIndex = entry.key;
        final questions = entry.value;
        
        await firestore.collection('quizzes').doc('lesson_$lessonIndex').set({
          'lessonIndex': lessonIndex,
          'title': lessonTitles[lessonIndex] ?? 'Unknown Lesson',
          'questions': questions,
        });
        
        setState(() {
          _status = 'Uploaded lesson $lessonIndex';
        });
      }
      
      setState(() {
        _status = 'All quizzes uploaded successfully!';
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Quiz Data'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (_isUploading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _uploadQuizData,
                  child: const Text('Upload Quiz Data to Firebase'),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 