import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../NetworkHandler.dart';
import '../SlideshowPage.dart';
import 'HomePage.dart';

class EmailSignUpPage extends StatefulWidget {
  const EmailSignUpPage({
    super.key,
    required this.setLocale,
  });

  final Function(Locale) setLocale;

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  bool visible = true; // for password visibility toggle
  final _globalKey = GlobalKey<FormState>();
  NetworkHandler networkHandler = NetworkHandler();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? errorText;
  bool validate = false;
  bool circular = false;
  String? selectedRole = "user"; // Default role

  final storage = FlutterSecureStorage();
  var log = Logger();

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
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
            child: Form(
              key: _globalKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo or Icon
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  // Role Dropdown

                  // Title
                  const Text(
                    "Create an Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Sign up to get started",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Username Input
                  usernameTextField(),
                  const SizedBox(height: 20),

                  // Email Input
                  emailTextField(),
                  const SizedBox(height: 20),

                  // Password Input
                  passwordTextField(),
                  const SizedBox(height: 30),

                  kIsWeb? Center( //web part//////////////////////////
                    child: SizedBox(
                      width: 400,
                      child: DropdownButtonFormField<String>(
                        padding: EdgeInsets.only(bottom: 15),
                        value: selectedRole,
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                        items: [
                          DropdownMenuItem(value: "user", child: Text("User")),
                          DropdownMenuItem(
                              value: "customer", child: Text("Customer")),
                          DropdownMenuItem(value: "admin", child: Text("Admin")),
                        ],
                        decoration: InputDecoration(
                          labelText: "Select Role",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ):
                  DropdownButtonFormField<String>(
                    padding: EdgeInsets.only(bottom: 15),
                    value: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                    items: [
                      DropdownMenuItem(value: "user", child: Text("User")),
                      DropdownMenuItem(
                          value: "customer", child: Text("Customer")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    decoration: InputDecoration(
                      labelText: "Select Role",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Sign-Up Button
                  InkWell(
                    onTap: () async {
                      setState(() {
                        circular = true;
                      });
                      await checkUser(); //check user first before sending data to Database server

                      if (_globalKey.currentState!.validate() && validate) {
                        //if validation is successful then send data  to Database server
                        Map<String, String> data = {
                          //username, email,password should be small just like the server
                          "username": _usernameController.text,
                          "email": _emailController.text,
                          "password": _passwordController.text,
                          "role": selectedRole ?? "user",
                        }; // to get the values of textfields as a map
                        print(data);
                        var response =
                            await networkHandler.post("/user/register", data);

                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          Map<String, dynamic> data = {
                            "username": _usernameController.text,
                            "password": _passwordController.text,
                          };

                          var response =
                              await networkHandler.post("/user/login", data);

                          if (response.statusCode == 200 ||
                              response.statusCode == 201) {
                            // Successfully logged in
                            Map<String, dynamic> output =
                                json.decode(response.body);
                            print(output['token']); // Print or store the token

                            await storage.write(
                                key: "token",
                                value: output[
                                    'token']); //store token in secure storage after login

                            await storage.write(
                                key: "role",
                                value: output['role']); // Store the role

                            setState(() {
                              validate = true;
                              circular = false;
                            });
                            Navigator.pushAndRemoveUntil(
                              //remove all the previous pages and you cannot go back to them like login page etc..
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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Something went wrong")));
                          }
                        }
                        setState(() {
                          circular = false;
                        });
                      } else {
                        setState(() {
                          circular = false;
                        });
                      }
                    },
                    child: circular
                        ? CircularProgressIndicator()
                        : Container(
                            width: 150,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade300,
                                  Colors.green.shade300
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                  // InkWell(
                  //   onTap: () async {
                  //     setState(() {
                  //       circular = true;
                  //     });
                  //     await checkUser();
                  //
                  //     if (_globalKey.currentState!.validate() && validate) {
                  //       Map<String, String> data = {
                  //         "username": _usernameController.text,
                  //         "email": _emailController.text,
                  //         "password": _passwordController.text,
                  //       };
                  //
                  //       var response = await networkHandler.post("/user/register", data);
                  //
                  //       if (response.statusCode == 200 || response.statusCode == 201) {
                  //         Navigator.pushAndRemoveUntil(
                  //           context,
                  //           MaterialPageRoute(builder: (context) => HomePage(setLocale: (_) {})),
                  //               (route) => false,
                  //         );
                  //       } else {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(content: Text("Something went wrong")),
                  //         );
                  //       }
                  //     }
                  //
                  //     setState(() {
                  //       circular = false;
                  //     });
                  //   },
                  //   child: Container(
                  //     width: double.infinity,
                  //     height: 50,
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(10),
                  //       gradient: LinearGradient(
                  //         colors: [Colors.teal.shade300, Colors.green.shade300],
                  //       ),
                  //     ),
                  //     child: Center(
                  //       child: circular
                  //           ? const CircularProgressIndicator(color: Colors.white)
                  //           : const Text(
                  //         "Sign Up",
                  //         style: TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 20),

                  // Already Have an Account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkUser() async {
    try {
      if (_usernameController.text.isEmpty) {
        setState(() {
          circular = false;
          validate = false;
          errorText = "Username can’t be empty";
        });
      } else {
        var response = await networkHandler
            .get("/user/checkusername/${_usernameController.text}");
        if (response != null && response['Status'] != null) {
          if (response["Status"]) {
            setState(() {
              circular = false;
              validate = false;
              errorText = "Username already taken";
            });
          } else {
            setState(() {
              errorText = null;
              validate = true;
            });
          }
        } else {
          setState(() {
            circular = false;
            validate = false;
            errorText = "Error checking username. Try again.";
          });
        }
      }
    } catch (e) {
      log.e("Network error: $e");
      setState(() {
        circular = false;
        validate = false;
        errorText = "Network error. Please try again later.";
      });
    }
  }

  Widget usernameTextField() {
    return kIsWeb //web part//////////////
        ? Center(
            // Center the TextField for a web layout
            child: SizedBox(
              width: 400, // Fixed width for a web-friendly size
              child: TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Enter your username",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600, // Subtle hint text color
                    fontSize: 14, // Slightly smaller font for a cleaner look
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  prefixIcon: const Icon(Icons.person, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Softer corners
                  ),
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
    return kIsWeb //web part//////////////////
        ? Center(
          child: SizedBox(
             width: 400,
            child: TextFormField(
                controller: _passwordController,
                obscureText: visible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password can’t be empty!';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters!';
                  }
                  return null;
                },
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
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
          ),
        )
        : TextFormField(
            controller: _passwordController,
            obscureText: visible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password can’t be empty!';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters!';
              }
              return null;
            },
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
            ),
          );
  }
}
