import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../SlideshowPage.dart';
import 'HomePage.dart';

class CheckVerificationPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const CheckVerificationPage({super.key, required this.setLocale});

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
    }
  }

  Future<void> resendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Verification email has been sent."),
        ),
      );
    }
  }

  Widget buildStyledButton({required String label, required VoidCallback onPressed}) {
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
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
            colors: [Colors.white, Colors.green[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 1.0],
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
