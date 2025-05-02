import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';

class CertificateGenerator extends StatefulWidget {
  const CertificateGenerator({super.key});

  @override
  State<CertificateGenerator> createState() => _CertificateGeneratorState();
}

class _CertificateGeneratorState extends State<CertificateGenerator> {
  String? _certificatePath;
  String? _previewPath;
  String? _fullName;
  bool _isLoading = true;
  List<Map<String, dynamic>> _moduleStatus = [];

  // List of all modules in the course
  final List<Map<String, dynamic>> _allModules = [
    {
      'id': 'introduction',
      'title': 'Introduction to Design Thinking',
      'index': 0,
    },
    {'id': 'empathize', 'title': 'Empathize', 'index': 1},
    {'id': 'define', 'title': 'Define', 'index': 2},
    {'id': 'ideate', 'title': 'Ideate', 'index': 3},
    {'id': 'prototype', 'title': 'Prototype', 'index': 4},
    {'id': 'test', 'title': 'Test', 'index': 5},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndModuleStatus();
  }

  Future<void> _fetchUserDataAndModuleStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch user name
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String firstName = userDoc['firstName'] ?? '';
      String lastName = userDoc['lastName'] ?? '';
      String fullName = '$firstName $lastName'.trim();

      // Prepare module status list with completion data
      List<Map<String, dynamic>> moduleStatusList = [];

      // Fetch completed modules directly
      QuerySnapshot completedModules =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('completedModules')
              .get();

      // Create a set of completed module titles from the completedModules collection
      Set<String> completedModuleTitles = {};
      for (var doc in completedModules.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Check both title and name fields
        if (data.containsKey('title')) {
          completedModuleTitles.add(data['title'].toString());
        } else if (data.containsKey('name')) {
          completedModuleTitles.add(data['name'].toString());
        }
      }

      // Fetch quiz scores to determine completion status
      QuerySnapshot quizScores =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('quiz_scores')
              .orderBy('timestamp', descending: true)
              .get();

      // Create a map to track highest scores for each module
      Map<int, int> highestScores = {};
      Map<int, int> totalQuestions = {};
      Map<String, bool> modulePassedByTitle = {};

      // Process quiz scores
      for (var doc in quizScores.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Handle both by index and by title
        int lessonIndex = data['lessonIndex'] ?? 0;
        String moduleTitle = data['moduleTitle']?.toString() ?? '';
        int score = data['score'] ?? 0;
        int total = data['totalQuestions'] ?? 10;
        bool passed = data['passed'] ?? false;

        // Track by index
        if (!highestScores.containsKey(lessonIndex) ||
            highestScores[lessonIndex]! < score) {
          highestScores[lessonIndex] = score;
          totalQuestions[lessonIndex] = total;
        }

        // Also track by title
        if (moduleTitle.isNotEmpty) {
          if (passed) {
            modulePassedByTitle[moduleTitle] = true;
          }
        }
      }

      // Check module completion status based on quiz scores and completed modules
      for (var module in _allModules) {
        int moduleIndex = module['index'];
        String moduleTitle = module['title'];
        
        // Module is completed if:
        // 1. It's in the completedModules collection, OR
        // 2. It passed a quiz with 70% or higher, OR
        // 3. It's marked as passed in the quiz_scores
        bool isCompleted = 
            completedModuleTitles.contains(moduleTitle) ||
            modulePassedByTitle[moduleTitle] == true ||
            (highestScores.containsKey(moduleIndex) &&
            (highestScores[moduleIndex]! / totalQuestions[moduleIndex]!) >= 0.7);

        moduleStatusList.add({
          'id': module['id'],
          'title': moduleTitle,
          'index': moduleIndex,
          'isCompleted': isCompleted,
          'highestScore': highestScores[moduleIndex] ?? 0,
          'totalQuestions': totalQuestions[moduleIndex] ?? 10,
        });
      }

      setState(() {
        _fullName = fullName;
        _moduleStatus = moduleStatusList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> generateCertificate(
    String name,
    String moduleTitle,
    int moduleIndex,
  ) async {
    final pdf = pw.Document();
    final ByteData bytes = await rootBundle.load('assets/template.png');
    final Uint8List byteList = bytes.buffer.asUint8List();

    String formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(pw.MemoryImage(byteList), fit: pw.BoxFit.cover),
              ),
              pw.Positioned(
                left: 0,
                right: 0,
                top: 280,
                child: pw.Center(
                  child: pw.Text(name, style: pw.TextStyle(fontSize: 35)),
                ),
              ),
              pw.Positioned(
                left: 0,
                right: 0,
                top: 340,
                child: pw.Center(
                  child: pw.Text(
                    "for successfully completing the module:",
                    style: pw.TextStyle(fontSize: 16),
                  ),
                ),
              ),
              pw.Positioned(
                left: 0,
                right: 0,
                top: 370,
                child: pw.Center(
                  child: pw.Text(
                    moduleTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                left: 110,
                top: 500,
                child: pw.Text(
                  formattedDate,
                  style: pw.TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final previewFile = File(
      "${tempDir.path}/certificate_${moduleIndex}_preview.pdf",
    );
    await previewFile.writeAsBytes(await pdf.save());

    setState(() {
      _previewPath = previewFile.path;
    });

    _showPreviewDialog(moduleTitle, moduleIndex);
  }

  void _showPreviewDialog(String moduleTitle, int moduleIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          title: Text("$moduleTitle Certificate Preview"),
          content:
              _previewPath == null
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    height: 400,
                    child: PDFView(
                      filePath: _previewPath!,
                      enableSwipe: true,
                      autoSpacing: false,
                      pageSnap: true,
                      fitPolicy: FitPolicy.BOTH,
                      onRender: (pages) {
                        print("PDF rendered with $pages pages");
                      },
                      onError: (error) {
                        print("Error loading PDF: $error");
                        Navigator.pop(context);
                        _showErrorDialog();
                      },
                    ),
                  ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await saveCertificate(moduleTitle, moduleIndex);
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveCertificate(String moduleTitle, int moduleIndex) async {
    if (_previewPath == null) return;

    final output = await getApplicationDocumentsDirectory();
    final fileName =
        "certificate_${moduleTitle.replaceAll(' ', '_').toLowerCase()}.pdf";
    final savedFile = File("${output.path}/$fileName");
    await File(_previewPath!).copy(savedFile.path);

    setState(() {
      _certificatePath = savedFile.path;
    });

    print("Certificate saved at: ${savedFile.path}");
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text("Failed to load preview. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Certificate Generator",
          style: TextStyle(fontSize: 20),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Available Certificates",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Complete a module quiz with at least 70% score to unlock its certificate",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _moduleStatus.length,
                        itemBuilder: (context, index) {
                          final module = _moduleStatus[index];
                          final bool isCompleted = module['isCompleted'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isCompleted
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                width: isCompleted ? 2 : 1,
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
                                        isCompleted
                                            ? Icons.check_circle
                                            : Icons.lock,
                                        color:
                                            isCompleted
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          module['title'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isCompleted
                                                    ? Colors.black
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isCompleted
                                        ? "Best Score: ${module['highestScore']}/${module['totalQuestions']} (${((module['highestScore'] / module['totalQuestions']) * 100).toStringAsFixed(1)}%)"
                                        : "Complete the quiz to unlock this certificate",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isCompleted
                                              ? Colors.black
                                              : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          isCompleted && _fullName != null
                                              ? () => generateCertificate(
                                                _fullName!,
                                                module['title'],
                                                module['index'],
                                              )
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xff75DBCE,
                                        ),
                                        foregroundColor: Colors.black,
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                      ),
                                      child: Text(
                                        isCompleted
                                            ? "Generate Certificate"
                                            : "Certificate Locked",
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
                    if (_certificatePath != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Card(
                          color: Colors.green[50],
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Certificate Generated!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_certificatePath != null) {
                                      OpenFile.open(_certificatePath);
                                    }
                                  },
                                  child: const Text("Open Certificate"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
