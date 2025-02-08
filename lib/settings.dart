import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/personal_info.dart';
import 'package:flutter_application_1/widget/dart_mode_switch.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var logger = Logger();

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String selectedLanguage = "EN";
  bool isDarkMode = false;
  String userName = "";
  String imageUrl = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var userData =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (userData.exists) {
          setState(() {
            userName = userData["name"] ?? "Unknown User";
            imageUrl = userData["profileImage"] ?? "Unknown Image";
          });
        } else {
          logger.w("User data does not exist in Firestore");
        }
      } catch (e) {
        logger.w("Error fetching user data: $e");
      }
    } else {
      logger.w("No user is logged in");
    }
  }

  signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 45.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PersonalInfo()),
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage:  NetworkImage(imageUrl),
                    ),
                    const SizedBox(width: 25),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Personal Info",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.chevron_right_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightGreen.shade100,
                    ),
                    child: const Icon(Icons.public, color: Colors.lightGreen),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Language",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    selectedLanguage,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: "KZ",
                          child: Text("Kazakh"),
                        ),
                        PopupMenuItem<String>(
                          value: "RU",
                          child: Text("Russian"),
                        ),
                        PopupMenuItem<String>(
                          value: "EN",
                          child: Text("English"),
                        ),
                      ];
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.arrow_drop_down_sharp),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade100,
                    ),
                    child: const Icon(
                      Icons.notification_add,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Notifications",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.chevron_right_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
  width: double.infinity,
  child: Row(
    children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.purple.shade100,
        ),
        child: const Icon(Icons.dark_mode, color: Colors.purple),
      ),
      const SizedBox(width: 20),
      Text(
        "Dark Mode",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const Spacer(), 
      DarkModeSwitch(), 
    ],
  ),
),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.shade100,
                    ),
                    child: const Icon(Icons.help, color: Colors.orange),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Help",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: signout,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.red.shade200,
                    highlightColor: Colors.red.shade300,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade100,
                          ),
                          child: const Icon(
                            Icons.exit_to_app,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "Log out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}