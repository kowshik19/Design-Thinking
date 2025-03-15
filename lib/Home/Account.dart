import 'package:design_thinking/Home/Account/Certificate.dart';
import 'package:design_thinking/Home/Account/FAQ.dart';
import 'package:design_thinking/Home/Account/Profile.dart';
import 'package:design_thinking/Home/Account/Settings.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xffF4F5F9),
        title: Text(
          'Account',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 80, // Adjust size as needed
              backgroundImage: AssetImage("assets/HomeScreen_Profile.png"),
            ),
          ),
          SizedBox(height: 20),
          element_1("Edit Account", Profile()),
          SizedBox(height: 5),
          element_1("Settings And Privacy", Settings()),
          SizedBox(height: 5),
          element_1("Download Certificate", CertificateGenerator()),
          SizedBox(height: 5),
          element_1("FAQ’s", FAQ()),
          SizedBox(height: 5),
          element_1("Logout", Account()),
        ],
      ),
    );
  }

  Padding element_1(String names, Widget screen) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Expanded(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                names,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Icon(Icons.arrow_right),
            ],
          ),
        ),
      ),
    );
  }
}
