import 'dart:convert';

import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
                  Text(
                    AppLocalizations.of(context)!.welcome_back,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.sign_in_to_continue,
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
                            int profileFlag = output['profileFlag'] ??
                                0; // Default to 0 if not provided
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
                            // bool hasProfile = await checkProfileFlag();
                            setState(() {
                              circular = false;
                            });

                            // if(kIsWeb)
                            //   hasProfile=true;

                            if (profileFlag == 1) {
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
                                      AppLocalizations.of(context)!
                                          .complete_your_profile,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    content: Text(
                                      AppLocalizations.of(context)!
                                          .please_create_profile,
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          AppLocalizations.of(context)!.cancel,
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
                                          AppLocalizations.of(context)!
                                              .create_profile,
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
                          // Check for banned account using the response data
                          var output = json.decode(response.body);
                          // If the response contains a "message" key that mentions "banned"
                          if (output is Map &&
                              output.containsKey('message') &&
                              output['message']
                                  .toString()
                                  .toLowerCase()
                                  .contains("banned")) {
                            setState(() {
                              circular = false;
                            });
                            // Show an AlertDialog for banned account

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(Icons.block, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text(AppLocalizations.of(context)!
                                          .account_banned),
                                    ],
                                  ),
                                  content: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.orange),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                        AppLocalizations.of(context)!.outputMessage
                                          ,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        logout(); // Optionally log the user out
                                      },
                                      icon: const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      label: Text(
                                        AppLocalizations.of(context)!.ok,
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            // For other errors, update errorText and UI as before
                            errorText =
                                output is Map && output.containsKey('msg')
                                    ? output['msg']
                                    : output.toString();
                            setState(() {
                              circular = false;
                              validate = false;
                            });
                          }
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
                            :  Text(
                                AppLocalizations.of(context)!.sign_in,
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
                              child:  Text(
                                AppLocalizations.of(context)!.forgot_password,
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
                            child:  Text(
                              AppLocalizations.of(context)!.forgot_password,
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
                       Text(
                       AppLocalizations.of(context)!.dont_have_account,
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
                        child:  Text(
                          AppLocalizations.of(context)!.sign_up,
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
                  hintText: AppLocalizations.of(context)!.enter_your_username,
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
    return kIsWeb //web part///////////////
        ? Center(
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: _passwordController,
                obscureText: visible,
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
                  errorText: validate ? null : errorText,
                ),
              ),
            ),
          )
        : TextFormField(
            controller: _passwordController,
            obscureText: visible,
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
              errorText: validate ? null : errorText,
            ),
          );
  }
}
