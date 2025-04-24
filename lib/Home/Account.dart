import 'package:design_thinking/Home/Account/Certificate.dart';
import 'package:design_thinking/Home/Account/FAQ.dart';
import 'package:design_thinking/Home/Account/Logout.dart';
import 'package:design_thinking/Home/Account/Profile.dart';
import 'package:design_thinking/Home/Account/Settings.dart';
import 'package:design_thinking/Home/Home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

String fullName = "User"; // Default full name in case it is not found
String userName = "User Name";

class _AccountState extends State<Account> {
  // Variable to hold the user's profile image URL
  String? profileImageUrl;

  // Fetch the profile image URL and user name (first and last) from Firestore
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data (profile image, firstName, lastName) from Firestore
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch the user document from Firestore using the user's UID
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        // Cast the document data to a Map<String, dynamic>
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Check if the profileImageUrl, firstName, and lastName fields exist in Firestore document
        setState(() {
          profileImageUrl =
              userData['photoUrl'] ??
              null; // Default to null if field is missing
          String firstName =
              userData['firstName'] ??
              "First Name"; // Default to "First Name" if field is missing
          String lastName =
              userData['lastName'] ??
              "Last Name"; // Default to "Last Name" if field is missing
          fullName = "$firstName $lastName"; // Combine first and last name
          String userid = userDoc['username'] ?? 'UserName';
          userName = userid;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              ),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                SizedBox(
                  height: constraints.maxHeight * 0.05,
                ), // 5% of screen height
                // Display profile image (either from Firebase or default)
                Center(
                  child: CircleAvatar(
                    radius: constraints.maxWidth * 0.2, // 20% of screen width
                    backgroundImage:
                        profileImageUrl != null
                            ? NetworkImage(
                              profileImageUrl!,
                            ) // Display profile image from Firebase
                            : const AssetImage("assets/HomeScreen_Profile.png")
                                as ImageProvider, // Default profile image if not available
                  ),
                ),
                SizedBox(
                  height: constraints.maxHeight * 0.02,
                ), // Adjusted height for spacing
                Text(
                  userName, // Show full name (first name + last name)
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.05, // Scalable font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.05,
                    ),
                    children: [
                      element_1("Edit Account", Profile(), constraints),
                      element_1(
                        "Settings And Privacy",
                        AccountSettings(),
                        constraints,
                      ),
                      element_1(
                        "Download Certificate",
                        CertificateGenerator(),
                        constraints,
                      ),
                      element_1("FAQ’s", FAQ(), constraints),
                      element_1("Logout", LogoutScreen(), constraints),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper function to create each list item
  Widget element_1(String title, Widget screen, BoxConstraints constraints) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.015),
        child: Container(
          padding: EdgeInsets.all(constraints.minWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize:
                      constraints.maxWidth * 0.045, // 4.5% of screen width
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: constraints.maxWidth * 0.05, // 5% of screen width
              ),
            ],
          ),
        ),
      ),
    );
  }
}
