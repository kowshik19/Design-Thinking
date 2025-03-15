import 'package:design_thinking/Home/Home.dart';
import 'package:design_thinking/Login_screens/Forgot_password.dart';
import 'package:design_thinking/Login_screens/signup.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F5F9),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 15),
              Image.asset('assets/login_img.png'),
              SizedBox(height: 15),
              Text(
                'Hey Champ👋, \nLet’s Step into Your Zone ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 35),
              _buildLabel('Email'),
              SizedBox(height: 8),
              _buildTextField(hint: 'name@example.com'),
              SizedBox(height: 25),
              _buildLabel('Password'),
              SizedBox(height: 8),
              _buildTextField(
                hint: '********',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPassword()),
                    );
                  },
                  child: const Text(
                    'Forget password?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                height: 60,
                width: 265,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff75DBCE),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Login', style: TextStyle(fontSize: 20)),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don’t Have an account ?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Signup()),
                      );
                    },
                    child: const Text(
                      'Signup',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
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

Widget _buildLabel(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
    ),
  );
}

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
