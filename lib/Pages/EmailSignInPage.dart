import 'dart:convert';

import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../NetworkHandler.dart';
import '../Profile/CreateProfile.dart';
import '../SlideshowPage.dart';
import 'EmailSignUpPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ForgotPasswordPage.dart';
import 'WelcomePage.dart';

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
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String? errorText;
  bool validate = false;
  bool circular = false;

  final storage = FlutterSecureStorage();

  Future<bool> checkProfileFlag() async {
    String? flag = await storage.read(key: "profileFlag");
    return flag == "1";
  }

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
                Colors.green[400]!,
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

                  // email Input
                  emailTextField(),

                  const SizedBox(height: 20),

                  // Password Input
                  passwordTextField(),

                  const SizedBox(height: 30),

                  // Sign-In Button
                  InkWell(
                    onTap: () async {
                      setState(() {
                        circular = true; // Show progress indicator
                      });

                      // Prepare login data
                      Map<String, dynamic> data = {
                        "email": _emailController.text,
                        "password": _passwordController.text,
                      };

                      try {
                        // Send login request to backend
                        var response =
                            await networkHandler.post("/user/login", data);

                        // Log response details for debugging
                        print("Login response code: ${response.statusCode}");
                        print("Login response body: ${response.body}");

                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          // Decode response to extract the token
                          Map<String, dynamic> output =
                              json.decode(response.body);

                          if (output.containsKey('token')) {
                            String jwtToken = output['token'];

                            // Store the JWT token in secure storage
                            await storage.write(key: "token", value: jwtToken);
                            await storage.write(
                                key: "email", value: _emailController.text);

                            // 🔥 Initialize Socket.io connection
                            networkHandler.initSocketConnection();

                            // 🔥 Join the socket.io chat using email
                            networkHandler.socket!
                                .emit('join_chat', _emailController.text);

                            // Store user role if available
                            if (output.containsKey('role')) {
                              await storage.write(
                                  key: "role", value: output['role']);
                            }

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
                            // Check if profile exists
                            bool hasProfile = await checkProfileFlag();
                            setState(() {
                              circular = false;
                            });

                            if(kIsWeb)
                              hasProfile=true;

                            if (hasProfile) {
                              // Navigate to SlideshowPage or HomePage
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
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
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                          logout(); // Logout the user
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                          "Create Profile",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CreateProfile()),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          } else {
                            throw Exception("Token not found in the response");
                          }
                        } else {
                          // Handle unsuccessful login attempts
                          var output;
                          try {
                            output = json.decode(response.body);
                            errorText =
                                output is Map && output.containsKey('msg')
                                    ? output['msg']
                                    : output.toString();
                          } catch (e) {
                            errorText = 'An unknown error occurred';
                          }
                          setState(() {
                            circular = false;
                            validate = false;
                          });
                        }
                      } catch (e) {
                        // Handle network or other errors
                        print("Login error: $e");
                        setState(() {
                          errorText = "Login failed. Please try again.";
                          circular = false;
                          validate = false;
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
                          padding: const EdgeInsets.only(left: 300),
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

  Widget emailTextField() {
    return kIsWeb //web part//////////////////
        ? Center(
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email can’t be empty!';
                  }
                  if (!value.contains("@")) {
                    return 'Invalid email!';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  prefixIcon: const Icon(Icons.email, color: Colors.black),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
          )
        : TextFormField(
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email can’t be empty!';
              }
              if (!value.contains("@")) {
                return 'Invalid email!';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: "Enter your email",
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              prefixIcon: const Icon(Icons.email, color: Colors.black),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
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
