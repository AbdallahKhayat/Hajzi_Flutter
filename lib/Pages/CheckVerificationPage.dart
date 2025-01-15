import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../NetworkHandler.dart';
import '../Profile/CreateProfile.dart';
import '../SlideshowPage.dart';
import 'HomePage.dart';
import 'package:http/http.dart' as http;

import 'WelcomePage.dart';

class CheckVerificationPage extends StatefulWidget {
  final Function(Locale) setLocale;
  final String email; // Add email as a parameter

  const CheckVerificationPage({
    super.key,
    required this.setLocale,
    required this.email,
  });

  @override
  _CheckVerificationPageState createState() => _CheckVerificationPageState();
}

class _CheckVerificationPageState extends State<CheckVerificationPage> {
  bool isVerified = false;
  bool isLoading = false;
  String? errorText;
  NetworkHandler networkHandler = NetworkHandler();
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkVerification();
  }

  // Function to send verification email using EmailJS
  Future<void> sendVerificationEmail(String email) async {
    try {
      final serviceId =
          'service_8eg3t9i'; // Replace with your EmailJS Service ID
      final templateId =
          'template_f69skpr'; // Replace with your EmailJS Template ID
      final userId = '3QhZNOXQgjXaKjDRk'; // Replace with your EmailJS User ID

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost'
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'from_name': "Hajzi Team",
            'to_name': email,
            'to_email': email,
            'reset_link':
                'https://hajzi-6883b1f029cf.herokuapp.com/user/verify/$email',
          },
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e) {
      errorText = 'Error while sending email: $e';
    }
  }

  Future<bool> checkVerificationStatus(String email) async {
    final response = await networkHandler.get2E('/user/isVerified/$email',
        requireAuth: false);

    if (response != null && response['verified'] != null) {
      return response['verified'] == true;
    } else {
      throw Exception('Failed to fetch verification status');
    }
  }

  // Function to resend verification email
  Future<void> resendVerificationEmail() async {
    await sendVerificationEmail(widget.email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Verification email has been sent."),
      ),
    );
  }

  // Method to check if profile exists
  Future<bool> checkProfileFlag() async {
    String? flag = await storage.read(key: "profileFlag");
    return flag == "1";
  }

  // Logout method
  void logout() async {
    await storage.delete(key: "token");
    await storage.delete(key: "email");
    await storage.delete(key: "role");
    await storage.delete(key: "profileFlag"); // Clear profileFlag
    // Delete other stored keys if necessary

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomePage(setLocale: widget.setLocale),
      ),
      (route) => false,
    );
  }

  // Function to check verification status via NetworkHandler
  Future<void> checkVerification() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      bool verified = await checkVerificationStatus(widget.email);
      setState(() {
        isVerified = verified;
      });

      if (isVerified) {
        bool hasProfile = await checkProfileFlag();

        final response = await networkHandler
            .post("/user/verifyToFalse/${widget.email}", {});
        print("POST /verifyToFalse: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (hasProfile) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => SlideshowPage(
                onDone: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage(
                              setLocale: widget.setLocale,
                              filterState: 0,
                            )),
                  );
                },
              ),
            ),
            (route) => false,
          );
        } else {
          // Show dialog prompting user to create profile
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  "Complete Your Profile",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text(
                    "Please create your profile to continue using the app."),
                actions: [
                  TextButton(
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      logout(); // Logout the user
                    },
                  ),
                  TextButton(
                    child: Text("Create Profile",
                        style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateProfile()),
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        errorText = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStyledButton(
      {required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 230,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.green.shade300],
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.green[400]!,
            ],
            begin: const FractionalOffset(0.0, 1.0),
            end: const FractionalOffset(0.0, 1.0),
            stops: const [0.0, 1.0],
            tileMode: TileMode.repeated,
          ),
        ),
        child: Center(
          child: isVerified
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Please verify your email. Check your inbox and click 'I Have Verified' once you complete verification.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 20),
                    buildStyledButton(
                      label: "I Have Verified",
                      onPressed: checkVerification,
                    ),
                    SizedBox(height: 10),
                    buildStyledButton(
                      label: "Resend Verification Email",
                      onPressed: resendVerificationEmail,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../SlideshowPage.dart';
// import 'HomePage.dart';
//
// class CheckVerificationPage extends StatefulWidget {
//  final Function(Locale) setLocale;
//   const CheckVerificationPage({super.key,required this.setLocale});
//   @override
//   _CheckVerificationPageState createState() => _CheckVerificationPageState();
// }
//
// class _CheckVerificationPageState extends State<CheckVerificationPage> {
//   bool isVerified = false;
//
//   @override
//   void initState() {
//     super.initState();
//     checkVerification();
//   }
//
//   Future<void> checkVerification() async {
//     User? user = FirebaseAuth.instance.currentUser;
//
//     // Reload user to get the latest verification status
//     await user?.reload();
//     setState(() {
//       isVerified = user?.emailVerified ?? false;
//     });
//
//     // If verified, navigate to the homepage
//     if (isVerified) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (context) => SlideshowPage(
//             onDone: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => HomePage(
//                       setLocale: widget.setLocale,
//                       filterState: 0,
//                     )),
//               );
//             },
//           ),
//         ),
//             (route) => false,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: isVerified
//             ? CircularProgressIndicator()
//             : Text(
//           "Please verify your email. Check your inbox and refresh this page once verified.",
//           textAlign: TextAlign.center,
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: checkVerification,
//         child: Icon(Icons.refresh),
//       ),
//     );
//   }
// }
//
