import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'HomePage.dart';

class CheckVerificationPage extends StatefulWidget {
 final Function(Locale) setLocale;
  const CheckVerificationPage({super.key,required this.setLocale});
  @override
  _CheckVerificationPageState createState() => _CheckVerificationPageState();
}

class _CheckVerificationPageState extends State<CheckVerificationPage> {
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    checkVerification();
  }

  Future<void> checkVerification() async {
    User? user = FirebaseAuth.instance.currentUser;

    // Reload user to get the latest verification status
    await user?.reload();
    setState(() {
      isVerified = user?.emailVerified ?? false;
    });

    // If verified, navigate to the homepage
    if (isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(setLocale: widget.setLocale,filterState: 0,)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isVerified
            ? CircularProgressIndicator()
            : Text(
          "Please verify your email. Check your inbox and refresh this page once verified.",
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: checkVerification,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

