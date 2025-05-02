import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:design_thinking/Home/Home.dart';
import 'package:design_thinking/phone_authentication/phone_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:design_thinking/Login_screens/login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _profileImage;

  final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage(String uid) async {
    if (_profileImage == null) return null;

    final storageRef = FirebaseStorage.instance.ref().child(
      'profile_images/$uid.jpg',
    );
    await storageRef.putFile(_profileImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _signUpUser() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String username = _usernameController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        username.isEmpty) {
      _showMessage("All fields are required");
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      _showMessage("Please enter a valid email address");
      return;
    }

    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    if (!_usernameRegex.hasMatch(username)) {
      _showMessage(
        "Username can only contain letters, numbers, and underscores",
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Check if the username is already taken
      final usernameSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        _showMessage("Username is already taken");
        setState(() => _isLoading = false);
        return;
      }

      // Create the user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      String fullName = "$firstName $lastName";

      // Proceed with image upload only if image is picked
      String? photoUrl;
      if (_profileImage != null) {
        photoUrl = await _uploadImageToStorage(uid);
        if (photoUrl == null) {
          _showMessage("Profile image upload failed!");
          setState(() => _isLoading = false);
          return;
        }
      }

      // Store user details in Firestore (even without profile image)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'email': email,
        'username': username,
        'photoUrl': photoUrl ?? "", // Store empty string if no image
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("User document created with ID: $uid");

      // Verify if document is actually created
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        print("User document exists: ${userDoc.data()}");
      } else {
        print("User document creation failed!");
      }

      // Proceed to phone authentication screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PhoneAuth()),
      );
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
      print("Signup error: $e"); // Print to debug
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage(
                                    'assets/HomeScreen_Profile.png',
                                  )
                                  as ImageProvider,
                      child:
                          _profileImage == null
                              ? const Icon(
                                Icons.add_a_photo,
                                size: 30,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tap to upload profile picture'),

                  SizedBox(height: screenHeight * 0.02),
                  const Text(
                    'Hey Champ👋,\nLets Create Your Account ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),

                  _buildLabel('Name'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          hint: 'First Name',
                          controller: _firstNameController,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.05),
                      Expanded(
                        child: _buildTextField(
                          hint: 'Last Name',
                          controller: _lastNameController,
                        ),
                      ),
                    ],
                  ),

                  _buildLabel('Email address'),
                  _buildTextField(
                    hint: 'name@example.com',
                    controller: _emailController,
                  ),

                  _buildLabel('Username'),
                  _buildTextField(hint: '', controller: _usernameController),

                  _buildLabel('Password'),
                  _buildTextField(
                    hint: '********',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),
                  SizedBox(
                    height: screenHeight * 0.07,
                    width: screenWidth * 0.6,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUpUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff75DBCE),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                              : Text(
                                'Signup',
                                style: TextStyle(fontSize: screenWidth * 0.05),
                              ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'You have an account?',
                        style: TextStyle(fontSize: 18),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Login(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xff636D77),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          hintText: hint,
          hintStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xff636D77),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
