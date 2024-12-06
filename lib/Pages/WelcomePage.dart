import 'dart:convert';

import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'EmailSignInPage.dart';
import 'EmailSignUpPage.dart';
import 'package:http/http.dart' as http;

class WelcomePage extends StatefulWidget {
  final Function(Locale locale) setLocale;

  const WelcomePage({super.key, required this.setLocale});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late Animation<Offset> animation1;

  late AnimationController _controller2;
  late Animation<Offset> animation2;

  bool _isLogin = false;
  late Map data;
  final facebookLogin = FacebookAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    animation1 = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeOut),
    );

    _controller2 = AnimationController(
        duration: const Duration(milliseconds: 2500), vsync: this);
    animation2 = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.elasticInOut),
    );

    _controller1.forward();
    _controller2.forward();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.green[200]!,
            ],
            begin: const FractionalOffset(0.0, 1.0),
            end: const FractionalOffset(0.0, 1.0),
            stops: const [0.0, 1.0],
            tileMode: TileMode.repeated,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
          child: Column(
            children: [
              // SlideTransition(
              //   position: animation1,
              //   child: const Text(
              //     "Hajzi",
              //     style: TextStyle(
              //       fontSize: 38,
              //       fontWeight: FontWeight.w600,
              //       letterSpacing: 2,
              //     ),
              //   ),
              // ),

              ClipOval(
                child: Image.asset(
                  "assets/Hajzi.png",
                  width: 250, // Set the width
                  height: 300, // Set the height
                  fit: BoxFit.cover, // Adjust how the image should fit
                ),
              ),

              SizedBox(
                height:MediaQuery.of(context).size.height*0.01,
              ),
              SlideTransition(
                position: animation1,
                child: const Text(
                  "Reserve Now From Your Home!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              boxContainer("assets/google.png", "Sign up with Google", null),
              const SizedBox(height: 20),
              boxContainer("assets/Facebook_logo.png", "Sign up with Facebook",
                  onFBLogin),
              const SizedBox(height: 20),
              boxContainer(
                  "assets/email.png", "Sign up with Email", onEmailClick),
              const SizedBox(height: 30),
              SlideTransition(
                position: animation2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => EmailSignInPage(
                            setLocale: widget.setLocale,
                          ),
                        ));
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  onFBLogin() async {
    await FacebookAuth.instance.logOut();
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email'],
      loginBehavior: LoginBehavior.webOnly,
    );

    switch (result.status) {
      case LoginStatus.success:
        final accessToken = result.accessToken;
        if (accessToken != null) {
          final token = accessToken.tokenString;
          final response = await http.get(
            Uri.parse(
                "https://graph.facebook.com/v2.12/me?fields=name,picture,email&access_token=$token"),
          );
          final data1 = json.decode(response.body);
          print(data1);

          setState(() {
            _isLogin = true;
            //  fbPaypass();
            data = data1;
          });
        }
        break;
      case LoginStatus.cancelled:
      case LoginStatus.failed:
        setState(() {
          _isLogin = false;
        });
        break;
      case LoginStatus.operationInProgress:
        break;
    }
  }

  Future fbPaypass() {
    return Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => HomePage(
              setLocale: widget.setLocale,
              filterState: 0,
            )));
  }

  onEmailClick() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EmailSignUpPage(
              setLocale: widget.setLocale,
            )));
  }

  Widget boxContainer(String path, String text, VoidCallback? onClick) {
    return kIsWeb //check if web or not///////////////////////////////////////////
        ? SlideTransition(
            position: animation2,
            child: InkWell(
              onTap: onClick,
              child: Container(
                height: 50, // Reduced height for a sleeker appearance
                width: 400, // Fixed width for consistency
                child: Card(
                  elevation: 2, // Add subtle elevation for a cleaner design
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 8), // Adjusted padding
                    child: Row(
                      children: [
                        Image.asset(
                          path,
                          height: 30, // Slightly smaller icon size
                          width: 30,
                        ),
                        const SizedBox(width: 15), // Reduced spacing
                        Expanded(
                          // Ensure the text doesn't overflow
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14, // Slightly smaller font size
                              color: Colors.black87,
                              fontWeight: FontWeight.w500, // Add subtle weight
                            ),
                            maxLines: 1, // Limit to a single line
                            overflow:
                                TextOverflow.ellipsis, // Ellipsis for overflow
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : SlideTransition(
            position: animation2,
            child: InkWell(
              onTap: onClick,
              child: Container(
                height: 60,
                width: MediaQuery.of(context).size.width - 120,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10),
                    child: Row(
                      children: [
                        Image.asset(
                          path,
                          height: 35,
                          width: 35,
                        ),
                        const SizedBox(width: 20),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
