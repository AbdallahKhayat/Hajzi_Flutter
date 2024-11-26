import 'dart:convert';

import 'package:blogapp/Pages/EmailSignInPage.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../NetworkHandler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ForgotPasswordPage extends StatefulWidget {
  final Function(Locale locale) setLocale; // Add this parameter

  const ForgotPasswordPage({super.key, required this.setLocale});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool visible = true;
  final _globalKey = GlobalKey<FormState>();
  NetworkHandler networkHandler = NetworkHandler();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? errorText;
  bool validate = false;
  bool circular = false;

  final storage = FlutterSecureStorage();

  var log = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.green[200]!,
            ],
            begin: const FractionalOffset(0.0, 1.0),
            end: const FractionalOffset(0.0, 1.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.repeated,
          ),
        ),
        child: Form(
          key: _globalKey,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Update Password",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Icon(
                  Icons.key, // Key icon for visual representation
                  size: 60,
                  color: Colors.black,
                ),
                const SizedBox(
                  height: 20,
                ),
                usernameTextField(),
                const SizedBox(
                  height: 15,
                ),
                passwordTextField(),
                const SizedBox(
                  height: 20,
                ),
                InkWell(
                  onTap: () async {
                    setState(() {
                      circular = true;
                    });

                    Map<String, dynamic> data = {
                      "username": _usernameController.text,
                      "password": _passwordController.text,
                    };

                    var response = await networkHandler.patch(
                        "/user/update/${data["username"]}", data);

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      setState(() {
                        validate = true;
                        circular = false;
                      });
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailSignInPage(
                            setLocale: widget.setLocale, // Pass setLocale
                          ),
                        ),
                            (route) => route.isFirst,
                      );
                    } else {
                      var output;
                      try {
                        output = json.decode(response.body);
                        if (output is Map && output.containsKey('msg')) {
                          errorText = output['msg'];
                        } else if (output is String) {
                          errorText = output;
                        }
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
                    width: 170,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade300, Colors.green.shade300],
                      ),
                    ),
                    child: Center(
                      child: circular
                          ? const CircularProgressIndicator()
                          : const Text(
                        "Update Password",
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget usernameTextField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        hintText: "Enter your username",
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        prefixIcon: const Icon(Icons.person, color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorText: validate ? null : errorText,
      ),
    );
  }

  Widget passwordTextField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: visible,
      decoration: InputDecoration(
        hintText: "Enter your new password",
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorText: validate ? null : errorText,
      ),
    );
  }
}

