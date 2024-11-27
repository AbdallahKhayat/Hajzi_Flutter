import 'dart:convert';

import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../NetworkHandler.dart';
import '../SlideshowPage.dart';
import 'EmailSignUpPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ForgotPasswordPage.dart';

class EmailSignInPage extends StatefulWidget {
  final Function(Locale) setLocale;

  const EmailSignInPage({super.key, required this.setLocale});

  @override
  State<EmailSignInPage> createState() => _EmailSignInPageState();
}

class _EmailSignInPageState extends State<EmailSignInPage> {
  bool visible = true; // Password visibility toggle
  final _globalKey = GlobalKey<FormState>();
  NetworkHandler networkHandler = NetworkHandler();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String? errorText;
  bool validate = false;
  bool circular = false;

  final storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
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
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 150.0),
            child: Form(
              key: _globalKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo or Icon
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Sign in to continue",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Username Input
                  usernameTextField(),

                  const SizedBox(height: 20),

                  // Password Input
                  passwordTextField(),

                  const SizedBox(height: 30),

                  // Sign-In Button
                  InkWell(
                    onTap: () async {
                      setState(() {
                        circular = true;
                      });

                      Map<String, dynamic> data = {
                        "username": _usernameController.text,
                        "password": _passwordController.text,
                      };

                      var response =
                          await networkHandler.post("/user/login", data);

                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        // Successful login
                        Map<String, dynamic> output =
                            json.decode(response.body);

                        await storage.write(
                            key: "token", value: output['token']);

                        // Store user role
                        await storage.write(
                            key: "role",
                            value: output['role']); // Store the role

                        // Load the stored language preference
                        String? storedLanguage =
                            await storage.read(key: "language");

                        // Update the locale if stored
                        if (storedLanguage != null) {
                          Locale newLocale = storedLanguage == "Arabic"
                              ? Locale('ar', 'AE')
                              : Locale('en', 'US');
                          widget.setLocale(newLocale);
                        }

                        setState(() {
                          validate = true;
                          circular = false;
                        });

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
                        // Handle errors
                        var output;
                        try {
                          output = json.decode(response.body);
                          errorText = output is Map && output.containsKey('msg')
                              ? output['msg']
                              : output.toString();
                        } catch (e) {
                          errorText = 'An unknown error occurred';
                        }

                        setState(() {
                          validate = false;
                          circular = false;
                        });
                      }
                    },
                    child: Container(
                      width: 150,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade300, Colors.green.shade300],
                        ),
                      ),
                      child: Center(
                        child: circular
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Forgot Password
                  kIsWeb
                      ? Padding(
                        padding: const EdgeInsets.only(left:300),
                        child: Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPasswordPage(
                                        setLocale: widget.setLocale),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordPage(
                                      setLocale: widget.setLocale),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                  const Spacer(),

                  // Sign-Up Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmailSignUpPage(
                                setLocale: widget.setLocale,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget usernameTextField() {
    return kIsWeb //web part///////////////
        ? Center(
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Enter your username",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  prefixIcon: const Icon(Icons.person, color: Colors.black),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorText: validate ? null : errorText,
                ),
              ),
            ),
          )
        : TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: "Enter your username",
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              prefixIcon: const Icon(Icons.person, color: Colors.black),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorText: validate ? null : errorText,
            ),
          );
  }

  Widget passwordTextField() {
    return kIsWeb //web part///////////////
        ? Center(
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: _passwordController,
                obscureText: visible,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                  suffixIcon: IconButton(
                    icon:
                        Icon(visible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        visible = !visible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorText: validate ? null : errorText,
                ),
              ),
            ),
          )
        : TextFormField(
            controller: _passwordController,
            obscureText: visible,
            decoration: InputDecoration(
              hintText: "Enter your password",
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              prefixIcon: const Icon(Icons.lock, color: Colors.black),
              suffixIcon: IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    visible = !visible;
                  });
                },
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorText: validate ? null : errorText,
            ),
          );
  }
}
