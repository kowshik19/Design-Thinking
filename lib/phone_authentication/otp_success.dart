import 'package:design_thinking/Home/Home.dart';
import 'package:design_thinking/Login_screens/signup.dart';
import 'package:flutter/material.dart';

class OtpSuccess extends StatefulWidget {
  const OtpSuccess({super.key});

  @override
  State<OtpSuccess> createState() => _OtpSuccessState();
}

class _OtpSuccessState extends State<OtpSuccess> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 25,
            children: [
              Center(
                child: Image.asset(
                  "assets/images/tick.png",
                  fit: BoxFit.contain,
                ),
              ),
              const Text(
                "Number Verfied\nSuccessfully",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF75DBCE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
