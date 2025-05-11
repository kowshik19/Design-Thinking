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
  double _overallMastery = 0.0;
  int _completedModules = 0;
  int _totalModules = 0;
  bool _certificateUnlocked = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndModuleStatus();
  }

  Future<void> _fetchUserDataAndModuleStatus() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch user name and overall mastery
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String uid = currentUser.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!mounted) return;

      String firstName = userDoc['firstName'] ?? '';
      String lastName = userDoc['lastName'] ?? '';
      String fullName = '$firstName $lastName'.trim();

      // Get overall mastery from user document
      double overallMastery = 0.0;
      if (userDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('overallMastery')) {
          overallMastery =
              (userData['overallMastery'] is double)
                  ? userData['overallMastery']
                  : (userData['overallMastery'] as num).toDouble();
        }
      }

      // Get module counts
      QuerySnapshot moduleSnapshot =
          await FirebaseFirestore.instance.collection('module').get();
      int totalModules = moduleSnapshot.docs.length;

      // Get completed modules count
      QuerySnapshot completedModulesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('completedModules')
              .get();
      int completedModules = completedModulesSnapshot.docs.length;

      // Certificate is unlocked ONLY if overall mastery is exactly 100%
      bool certificateUnlocked = overallMastery >= 100.0;

      if (!mounted) return;

      setState(() {
        _fullName = fullName;
        _overallMastery = overallMastery;
        _totalModules = totalModules;
        _completedModules = completedModules;
        _certificateUnlocked = certificateUnlocked;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> generateCertificate(String name) async {
    try {
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
                // Background template
                pw.Positioned.fill(
                  child: pw.Image(
                    pw.MemoryImage(byteList),
                    fit: pw.BoxFit.cover,
                  ),
                ),

                // Name
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: 280,
                  child: pw.Center(
                    child: pw.Text(
                      name,
                      style: pw.TextStyle(
                        fontSize: 35,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Date
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
        "${tempDir.path}/certificate_complete_preview.pdf",
      );
      await previewFile.writeAsBytes(await pdf.save());

      if (!mounted) return;

      setState(() {
        _previewPath = previewFile.path;
      });

      _showPreviewDialog();
    } catch (e) {
      print("Error generating certificate: $e");
      _showErrorDialog("Failed to generate certificate. Please try again.");
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          title: const Text("Course Completion Certificate"),
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
                        _showErrorDialog(
                          "Failed to load PDF preview. Please try again.",
                        );
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
                await saveCertificate();
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveCertificate() async {
    if (_previewPath == null) return;

    final output = await getApplicationDocumentsDirectory();
    final fileName = "design_thinking_certificate.pdf";
    final savedFile = File("${output.path}/$fileName");
    await File(_previewPath!).copy(savedFile.path);

    setState(() {
      _certificatePath = savedFile.path;
    });

    print("Certificate saved at: ${savedFile.path}");
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
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
        title: const Text("Certificate", style: TextStyle(fontSize: 20)),
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
                      "Course Completion Certificate",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Certificate card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color:
                              _certificateUnlocked
                                  ? Colors.green
                                  : Colors.grey.shade300,
                          width: _certificateUnlocked ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              _certificateUnlocked
                                  ? Icons.workspace_premium
                                  : Icons.lock,
                              size: 80,
                              color:
                                  _certificateUnlocked
                                      ? Colors.amber
                                      : Colors.grey,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _certificateUnlocked
                                  ? "Certificate Available!"
                                  : "Certificate Locked",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    _certificateUnlocked
                                        ? Colors.green.shade800
                                        : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _certificateUnlocked
                                  ? "Congratulations on completing all modules!"
                                  : "Complete all modules to unlock your certificate",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    _certificateUnlocked
                                        ? Colors.black87
                                        : Colors.grey,
                              ),
                            ),
                            // const SizedBox(height: 30),
                            // if (_certificateUnlocked && _fullName != null)
                            //   Container(
                            //     padding: const EdgeInsets.all(16),
                            //     decoration: BoxDecoration(
                            //       color: Colors.green.shade50,
                            //       borderRadius: BorderRadius.circular(12),
                            //       border: Border.all(
                            //         color: Colors.green.shade200,
                            //       ),
                            //     ),
                            //     child: Column(
                            //       children: [
                            //         const Text(
                            //           "Your certificate will include:",
                            //           style: TextStyle(
                            //             fontSize: 16,
                            //             fontWeight: FontWeight.bold,
                            //           ),
                            //         ),
                            //         const SizedBox(height: 12),
                            //         Row(
                            //           children: [
                            //             const Icon(
                            //               Icons.person,
                            //               color: Colors.blue,
                            //             ),
                            //             const SizedBox(width: 10),
                            //             Text(
                            //               "Name: $_fullName",
                            //               style: const TextStyle(fontSize: 16),
                            //             ),
                            //           ],
                            //         ),
                            //         const SizedBox(height: 8),
                            //         Row(
                            //           children: [
                            //             const Icon(
                            //               Icons.calendar_today,
                            //               color: Colors.blue,
                            //             ),
                            //             const SizedBox(width: 10),
                            //             Text(
                            //               "Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}",
                            //               style: const TextStyle(fontSize: 16),
                            //             ),
                            //           ],
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed:
                                    _certificateUnlocked && _fullName != null
                                        ? () => generateCertificate(_fullName!)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff75DBCE),
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _certificateUnlocked
                                      ? "Generate Certificate"
                                      : "Certificate Unavailable",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Certificate notification if generated
                    if (_certificatePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Card(
                          color: Colors.green[50],
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
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
