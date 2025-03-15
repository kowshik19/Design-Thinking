import 'dart:io';
import 'dart:typed_data';
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
  final TextEditingController _nameController = TextEditingController();

  Future<void> _generateCertificate() async {
    String userName = _nameController.text.trim();
    if (userName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a name")));
      return;
    }

    // Load the certificate template
    ByteData data = await rootBundle.load("assets/template.png");
    Uint8List bytes = data.buffer.asUint8List();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load certificate template.")),
      );
      return;
    }

    // Define text color and font
    img.drawString(image, font: img.arial48, x: 400, y: 500, userName);

    // Convert image to PNG
    Uint8List outputBytes = Uint8List.fromList(img.encodePng(image));

    // Save the image to local storage
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

    // Open the generated certificate
    OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Certificate Generator")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Enter your name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateCertificate,
              child: const Text("Generate Certificate"),
            ),
            const SizedBox(height: 20),
            if (_certificatePath != null)
              Text(
                "Saved at: $_certificatePath",
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
