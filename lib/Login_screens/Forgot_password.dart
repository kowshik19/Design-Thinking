import 'package:design_thinking/Login_screens/login.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Forget Password ?",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirm the email to send password reset Link . . . . . . . . . . . . . .',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xff636D77),
                ),
              ),
            ),
            SizedBox(height: 80),
            SizedBox(
              height: screenHeight * 0.07,
              width: screenWidth * 0.6,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff75DBCE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Get Link',
                  style: TextStyle(fontSize: screenWidth * 0.05),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
