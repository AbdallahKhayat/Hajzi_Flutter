import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'CreateProfile.dart';
import 'MainProfile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  NetworkHandler networkHandler = NetworkHandler();
  Widget page = CircularProgressIndicator();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkProfile();
  }

  void checkProfile() async {
    var response = await networkHandler.get("/profile/checkProfile");
    if (response["Status"] == true) {
      //if status is true (200)
      setState(() {
        page = MainProfile();
      });
    } else {
      setState(() {
        page = button();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: page,
    );
  }

  Widget showProfile() {
    return Center(
      child: Text("Profile Data is Available"),
    );
  }

  Widget button() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          kIsWeb
              ? Center(
                  child: Text(
                    "Tap the button below to add your profile data",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Text(
                  "Tap the button below to add your profile data",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateProfile()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: Colors.teal,
              shadowColor: Colors.teal.withOpacity(0.5),
              elevation: 8,
            ),
            child: kIsWeb
                ? const Text(
                    "Add Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text(
                    "Add Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
