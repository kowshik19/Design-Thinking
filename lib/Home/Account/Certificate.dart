import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CertificateGenerator extends StatefulWidget {
  const CertificateGenerator({super.key});

  @override
  State<CertificateGenerator> createState() => _CertificateGeneratorState();
}

class _CertificateGeneratorState extends State<CertificateGenerator> {
  String? _certificatePath;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      setState(() {
        _userName = userDoc['firstName'] ?? 'User';
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateCertificate() async {
    if (_userName == null || _userName!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User name not found!")));
      return;
    }

    ByteData data = await rootBundle.load("assets/template.png");
    Uint8List bytes = data.buffer.asUint8List();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load certificate template.")),
      );
      return;
    }

    img.drawString(
      image,
      _userName!,
      font: img.arial14,
      x: 100,
      y: 100,
      color: img.ColorFloat16.rgb(0, 0, 0),
    );

    Uint8List outputBytes = Uint8List.fromList(img.encodePng(image));

    Directory directory = await getApplicationDocumentsDirectory();
    String path = "${directory.path}/Generated_Certificate.png";
    File file = File(path);
    await file.writeAsBytes(outputBytes);

    setState(() {
      _certificatePath = path;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Certificate saved to: $path")));

    OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _isLoading
                ? const CircularProgressIndicator()
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Align(
                        child: const Text(
                          "Click the below button to generate certificate",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
            SizedBox(
              height: 60,
              width: 265,
              child: ElevatedButton(
                onPressed: _generateCertificate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff75DBCE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Generate', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 20),
            if (_certificatePath != null)
              Card(
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
                      const SizedBox(height: 5),
                      Text(
                        "Saved at: $_certificatePath",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
