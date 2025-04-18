import 'dart:async';
import 'package:design_thinking/phone_authentication/otp_success.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  int _secondsRemaining = 30;
  Timer? _timer;
  int _resendCount = 0;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCount++;
    int delay = 30 * (1 << (_resendCount - 1));

    setState(() {
      _secondsRemaining = delay;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining == 0) {
          timer.cancel();
        }
      });
    });
  }

  void _verifyCode() async {
    setState(() {
      _isVerifying = true;
    });

    String otp = _otpController.text.trim();

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    try {
      await _auth.signInWithCredential(credential);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Phone verified successfully!')),
      // );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpSuccess()),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });

      String errorMessage = e.toString().split(':').last.trim();
      _showErrorDialog(errorMessage);
    }
  }

  void _resendCode() {
    _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Optional: handle auto verification
      },
      verificationFailed: (FirebaseAuthException e) {
        // Extract only the main message from the error
        String errorMessage =
            e.message?.split(':').last.trim() ?? 'Failed to resend OTP';
        _showErrorDialog(errorMessage);
      },
      codeSent: (String newVerificationId, int? resendToken) {
        setState(() {
          verificationId = newVerificationId;
        });
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code resent successfully!')),
        );
      },
      codeAutoRetrievalTimeout: (String newVerificationId) {
        setState(() {
          verificationId = newVerificationId;
        });
      },
    );
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: SingleChildScrollView(
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Enter The Code",
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Center(
                  child: Image.asset(
                    "assets/images/inputOtp.png",
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  "The code has been sent to the Mobile Number ${widget.phoneNumber}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color.fromARGB(255, 108, 107, 107),
                  ),
                ),
                const SizedBox(height: 10),
                Pinput(
                  controller: _otpController,
                  length: 6,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _secondsRemaining > 0
                        ? "Resend Code in $_secondsRemaining sec"
                        : "Didn't receive it? Tap below to resend",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 108, 107, 107),
                    ),
                  ),
                ),
                if (_secondsRemaining == 0)
                  Center(
                    child: TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        "Resend Code",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF75DBCE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      child: Text(
                        "Verify Code",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isVerifying)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
