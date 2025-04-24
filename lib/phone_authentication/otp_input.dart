import 'dart:async';
import 'package:design_thinking/phone_authentication/otp_success.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpInput extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpInput({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();

  late String verificationId;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId;
  }

  void _verifyCode() async {
    setState(() => _isVerifying = true);

    String otp = _otpController.text.trim();

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Link phone to email account
        await user.linkWithCredential(credential);

        // Save phone number to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'phoneNumber': widget.phoneNumber,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Phone number linked successfully!")),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OtpSuccess()),
          ); // or push to a success screen
        }
      } else {
        _showErrorDialog("No user is signed in.");
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isVerifying = false);

      if (e.code == 'provider-already-linked') {
        _showErrorDialog("Phone number is already linked.");
      } else if (e.code == 'credential-already-in-use') {
        _showErrorDialog("This phone is used by another account.");
      } else {
        _showErrorDialog(e.message ?? "OTP verification failed.");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Enter the OTP Recieved",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Image.asset("assets/images/inputOtp.png"),
            Pinput(
              controller: _otpController,
              length: 6,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF75DBCE),
              ),
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  "Verify",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
            if (_isVerifying) const SizedBox(height: 20),
            if (_isVerifying) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
