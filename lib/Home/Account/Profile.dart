import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  String? _profileImageUrl; // For storing the user's profile image URL
  File? _selectedImage; // For storing the picked image file
  bool _isPickingImage = false; // Flag to prevent multiple image picker dialogs

  final _formKey = GlobalKey<FormState>();

  // Fetch the user data from Firestore
  Future<void> _fetchUserProfile() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _dobController.text = userData['dob'] ?? '';
        _schoolController.text = userData['school'] ?? '';
        _profileImageUrl =
            userData['profileImageUrl']; // Assuming the image URL is stored in Firestore
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching profile: $e")));
    }
  }

  // Pick an image using image_picker
  Future<void> _pickImage() async {
    if (_isPickingImage)
      return; // Prevent opening the picker if it's already active
    setState(() {
      _isPickingImage = true;
    });

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    ); // You can use ImageSource.camera for camera

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }

    setState(() {
      _isPickingImage = false; // Reset the flag after the image is picked
    });
  }

  // Upload the image to Firebase Storage
  Future<String> _uploadImage() async {
    if (_selectedImage == null)
      return ''; // If no image is selected, return empty string

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$uid.jpg',
      );
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Error uploading image: $e");
    }
  }

  // Select the date of birth
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  // Update profile data in Firestore
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;

        String imageUrl =
            _profileImageUrl ?? ''; // If there's an existing image URL, keep it

        if (_selectedImage != null) {
          // If a new image is selected, upload it to Firebase Storage and get the new URL
          imageUrl = await _uploadImage();
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'dob': _dobController.text,
          'school': _schoolController.text,
          'profileImageUrl': imageUrl, // Save the new profile image URL
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Profile Updated Successfully!",
              style: TextStyle(color: Colors.green),
            ),
            backgroundColor: Colors.white,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user profile data on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xffF4F5F9),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Profile Picture with Edit Option
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(
                                _selectedImage!,
                              ) // Show the selected image
                              : (_profileImageUrl != null
                                  ? NetworkImage(
                                    _profileImageUrl!,
                                  ) // Show the image from Firestore
                                  : const AssetImage(
                                        "assets/HomeScreen_Profile.png",
                                      )
                                      as ImageProvider),
                    ),
                    IconButton(
                      onPressed:
                          _pickImage, // Allow the user to pick a new image
                      icon: const Icon(Icons.edit, size: 30),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("Name"),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      hint: "First Name",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      hint: "Last Name",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildLabel("Email"),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailController,
                hint: "amar123@gmail.com",
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),
              _buildLabel("Date of Birth"),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _dobController,
                    hint: "Select your DOB",
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildLabel("School Name"),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _schoolController,
                hint: "ABC School",
              ),

              const SizedBox(height: 26),
              Center(child: _buildButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 52,
      width: 193,
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff75DBCE),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Update', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// Common Widget for Labels
Widget _buildLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.black,
    ),
  );
}

// Common Widget for Text Fields
Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  bool obscureText = false,
  Widget? suffixIcon,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Container(
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
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty';
        }
        if (keyboardType == TextInputType.emailAddress &&
            !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Enter a valid email';
        }
        return null;
      },
    ),
  );
}
