import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../NetworkHandler.dart';
import '../SlideshowPage.dart';
import 'CheckVerificationPage.dart';
import 'HomePage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
                'https://hajziapp-98152e888858.herokuapp.com/user/verify/$email',
          },
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.verification_email_sent)),
        );
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error while sending email: $e');
    }
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
                   Text(
                    AppLocalizations.of(context)!.create_account,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   Text(
                    AppLocalizations.of(context)!.sign_up_get_started,
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

                  // kIsWeb
                  //     ? Center(
                  //         //web part//////////////////////////
                  //         child: SizedBox(
                  //           width: 400,
                  //           child: DropdownButtonFormField<String>(
                  //             padding: EdgeInsets.only(bottom: 15),
                  //             value: selectedRole,
                  //             onChanged: (value) {
                  //               setState(() {
                  //                 selectedRole = value;
                  //               });
                  //             },
                  //             items: [
                  //               DropdownMenuItem(
                  //                   value: "user", child: Text("User")),
                  //               DropdownMenuItem(
                  //                   value: "customer", child: Text("Customer")),
                  //               DropdownMenuItem(
                  //                   value: "admin", child: Text("Admin")),
                  //             ],
                  //             decoration: InputDecoration(
                  //               labelText: "Select Role",
                  //               border: OutlineInputBorder(
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       )
                  //     : DropdownButtonFormField<String>(
                  //         padding: EdgeInsets.only(bottom: 15),
                  //         value: selectedRole,
                  //         onChanged: (value) {
                  //           setState(() {
                  //             selectedRole = value;
                  //           });
                  //         },
                  //         items: [
                  //           DropdownMenuItem(
                  //               value: "user", child: Text("User")),
                  //           DropdownMenuItem(
                  //               value: "customer", child: Text("Customer")),
                  //           DropdownMenuItem(
                  //               value: "admin", child: Text("Admin")),
                  //         ],
                  //         decoration: InputDecoration(
                  //           labelText: "Select Role",
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //         ),
                  //       ),

                  // Sign-Up Button
                  InkWell(
                    onTap: () async {
                      setState(() {
                        circular = true;
                      });

                      await checkUser(); // Check if the username already exists

                      if (_globalKey.currentState!.validate() && validate) {
                        try {
                          // Step 1: Create the user with Firebase
                          // UserCredential userCredential = await FirebaseAuth.instance
                          //     .createUserWithEmailAndPassword(
                          //   email: _emailController.text,
                          //   password: _passwordController.text,
                          // );

                          // Step 2: Send email verification
                          //  await userCredential.user!.sendEmailVerification();
                          await sendVerificationEmail(_emailController.text);

                          // Step 3: Send user data to backend for registration and token generation
                          Map<String, String> data = {
                            "username": _usernameController.text,
                            "email": _emailController.text,
                            "password": _passwordController.text,
                            // Optionally hashed on backend
                            "role": selectedRole ?? "user",
                          };

                          // Use NetworkHandler to make the backend request
                          var response =
                              await networkHandler.post("/user/register", data);

                          print("Raw response: ${response.body}");
                          if (response.statusCode == 200 ||
                              response.statusCode == 201) {
                            // Decode the response and retrieve the JWT token
                            var responseData = json.decode(response.body);
                            String jwtToken = responseData[
                                "token"]; // Ensure the token key matches your backend response

                            // Store the JWT token in secure storage
                            await storage.write(key: "token", value: jwtToken);
                            await storage.write(
                                key: "role", value: selectedRole);
                            await storage.write(
                                key: "email", value: _emailController.text);
                            // 🔥 Initialize profileFlag to "0" indicating profile not created
                            await storage.write(key: "profileFlag", value: "0");
                            // 🔥 Initialize Socket.io connection
                            networkHandler.initSocketConnection();

                            // 🔥 Join the socket.io chat using email
                            networkHandler.socket!
                                .emit('join_chat', _emailController.text);

                            // Show a success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.verification_email_sent),
                              ),
                            );

                            // Navigate to CheckVerificationPage or login screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckVerificationPage(
                                  email: _emailController.text,
                                  setLocale: widget.setLocale,
                                ),
                              ),
                            );
                          } else {
                            throw Exception(
                                "Failed to register user on the backend");
                          }
                        } catch (e) {
                          log.e("Sign-up error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sign-up failed: $e")),
                          );
                        } finally {
                          setState(() {
                            circular = false;
                          });
                        }
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
                                AppLocalizations.of(context)!.sign_up,
                                style: const TextStyle(
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
                       Text(
                        AppLocalizations.of(context)!.already_have_account,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child:  Text(
                          AppLocalizations.of(context)!.sign_in,
                          style: const TextStyle(
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
          errorText = AppLocalizations.of(context)!.username_empty;
        });
      } else {
        var response = await networkHandler
            .get("/user/checkemail/${_emailController.text}");
        if (response != null && response['Status'] != null) {
          if (response["Status"]) {
            setState(() {
              circular = false;
              validate = false;
              errorText = AppLocalizations.of(context)!.email_taken;
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
            errorText = AppLocalizations.of(context)!.error_checking_email;
          });
        }
      }
    } catch (e) {
      log.e("Network error: $e");
      setState(() {
        circular = false;
        validate = false;
        errorText = AppLocalizations.of(context)!.network_error;
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
                  hintText: AppLocalizations.of(context)!.enter_your_username,
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
              hintText: AppLocalizations.of(context)!.enter_your_username,
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
                    return AppLocalizations.of(context)!.email_cant_be_empty;
                  }
                  if (!value.contains("@")) {
                    return AppLocalizations.of(context)!.invalid_email;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enter_your_email,
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
                return AppLocalizations.of(context)!.email_cant_be_empty;
              }
              if (!value.contains("@")) {
                return AppLocalizations.of(context)!.invalid_email;
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enter_your_email,
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
                    return AppLocalizations.of(context)!.password_empty;
                  }
                  if (value.length < 8) {
                    return AppLocalizations.of(context)!.password_min_length;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enter_your_password,
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
                ),
              ),
            ),
          )
        : TextFormField(
            controller: _passwordController,
            obscureText: visible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.password_empty;
              }
              if (value.length < 8) {
                return AppLocalizations.of(context)!.password_min_length;
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enter_your_password,
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
