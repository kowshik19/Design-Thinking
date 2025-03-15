import 'package:design_thinking/Login_screens/login.dart';
import 'package:design_thinking/Login_screens/otp.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool _obscurePassword = true; // Controls password visibility

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
                  Image.asset(
                    'assets/login_img1.png',
                    width: screenWidth * 0.6,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  const Text(
                    'Hey Champ👋,\nLet’s Create Your Account ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Name Fields
                  _buildLabel('Name'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(hint: 'First Name')),
                      SizedBox(width: screenWidth * 0.05),
                      Expanded(child: _buildTextField(hint: 'Last Name')),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.025),

                  // Email Field
                  _buildLabel('Email address'),
                  _buildTextField(hint: 'name@example.com'),

                  SizedBox(height: screenHeight * 0.025),

                  // Password Field
                  _buildLabel('Create Password'),
                  _buildTextField(
                    hint: '********',
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

                  // Signup Button
                  _build_button(screenHeight, screenWidth, context),

                  SizedBox(height: screenHeight * 0.02),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'You have an account?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
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

  SizedBox _build_button(
    double screenHeight,
    double screenWidth,
    BuildContext context,
  ) {
    return SizedBox(
      height: screenHeight * 0.07,
      width: screenWidth * 0.6,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OTP()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff75DBCE),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text('Signup', style: TextStyle(fontSize: screenWidth * 0.05)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Color(0xff636D77),
        ),
      ),
    );
  }

  // Helper method for text fields
  Widget _buildTextField({
    required String hint,
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
