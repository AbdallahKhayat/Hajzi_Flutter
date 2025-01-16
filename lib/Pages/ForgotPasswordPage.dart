import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../NetworkHandler.dart';
import 'EmailSignInPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  final Function(Locale locale) setLocale;

  const ForgotPasswordPage({Key? key, required this.setLocale}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _globalKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool visible = true;
  bool circular = false;
  //String buttonText = "Verify Email";
  bool isVerified = false;
  String? errorText;
  late String buttonText;
  /// Store which email has been verified
  String? verifiedEmail;




  NetworkHandler networkHandler = NetworkHandler();

  Future<void> sendVerificationEmail(String email) async {
    try {
      final serviceId = 'service_8eg3t9i'; // Replace with your EmailJS Service ID
      final templateId = 'template_xcrzqrq'; // Replace with your EmailJS Template ID
      final userId = '3QhZNOXQgjXaKjDRk'; // Replace with your EmailJS User ID

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'origin': 'http://localhost'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'from_name': "Hajzi Team",
            'to_name': email,
            'to_email': email,
            'reset_link': 'https://hajzi-6883b1f029cf.herokuapp.com/user/verify/$email',
          },
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.verifyYourEmail)),
        );
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error while sending email: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    buttonText = AppLocalizations.of(context)!.verifyEmail; // CHANGED
  }

  Future<bool> checkVerificationStatus(String email) async {
    final response =
    await networkHandler.get2E('/user/isVerified/$email', requireAuth: false);

    if (response != null && response['verified'] != null) {
      return response['verified'] == true;
    } else {
      throw Exception('Failed to fetch verification status');
    }
  }

  Future<void> updatePassword(String email, String password) async {
    final response = await networkHandler.patch2E(
      '/user/update/$email',
      {
        'password': password,
        'verified': false // Explicitly reset verified status to false
      },
      requireAuth: false,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update password');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccessfully)), // CHANGED
    );

    // Reset local state
    setState(() {
      isVerified = false;
      buttonText = AppLocalizations.of(context)!.verifyEmail; // CHANGED
    });

    // Navigate to EmailSignInPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmailSignInPage(
          setLocale: widget.setLocale,
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
            colors: [Colors.white, Colors.green[400]!],
            begin: const FractionalOffset(0.0, 1.0),
            end: const FractionalOffset(0.0, 1.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.repeated,
          ),
        ),
        child: Form(
          key: _globalKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.forgotPassword, // CHANGED
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.key,
                  size: 60,
                  color: Colors.black,
                ),
                const SizedBox(height: 20),
               if(!isVerified) emailTextField(),
                const SizedBox(height: 15),
                if (isVerified) passwordTextField(),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    if (_globalKey.currentState!.validate()) {
                      setState(() {
                        circular = true;
                      });

                      try {
                        if (!isVerified) {
                          // Check verification status before sending an email
                          bool alreadyVerified =
                          await checkVerificationStatus(_emailController.text);

                          if (alreadyVerified) {
                            setState(() {
                              verifiedEmail = _emailController.text;
                              isVerified = true;
                              buttonText = AppLocalizations.of(context)!.updatePassword; // CHANGED
                            });
                          } else {
                            // Send verification email
                            await sendVerificationEmail(_emailController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.pleaseVerifyYourEmail), // CHANGED
                              ),
                            );
                          }
                        } else {
                          // If isVerified is true, ensure the email hasn't changed
                          if (_emailController.text != verifiedEmail) {
                            setState(() {
                              isVerified = false;
                              buttonText = "Verify Email";
                            });
                            throw Exception(
                                "Email changed. Please re-verify the new email.");
                          }

                          // Update the password
                          await updatePassword(
                            _emailController.text,
                            _passwordController.text,
                          );
                        }
                      } catch (e) {
                        setState(() {
                          errorText = e.toString();
                        });
                      } finally {
                        setState(() {
                          circular = false;
                        });
                      }
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
                          : Text(
                        buttonText,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
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

  Widget emailTextField() {
    return kIsWeb //web part//////////////////
        ? Center(
      child: SizedBox(
        width: 400,
        child: TextFormField(
          controller: _emailController,
         // readOnly: isVerified, // Disable editing if verified
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.emailEmpty; // CHANGED
            }
            if (!value.contains("@")) {
              return AppLocalizations.of(context)!.invalidEmail; // CHANGED
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterYourEmail, // CHANGED
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
    ):
    TextFormField(
      controller: _emailController,
    //  readOnly: isVerified, // Disable editing if verified
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.emailEmpty; // CHANGED
        }
        if (!value.contains("@")) {
          return AppLocalizations.of(context)!.invalidEmail; // CHANGED
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.enterYourEmail, // CHANGED
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        prefixIcon: const Icon(Icons.email, color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.passwordEmpty; // e.g., "Password cannot be empty"
            }
            if (value.length < 8) {
              return AppLocalizations.of(context)!.passwordMinLength; // e.g., "Password must be at least 8 characters"
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterYourNewPassword, // CHANGED
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
    ):
   TextFormField(
      controller: _passwordController,
      obscureText: visible,
     validator: (value) {
       if (value == null || value.isEmpty) {
         return AppLocalizations.of(context)!.passwordEmpty; // e.g., "Password cannot be empty"
       }
       if (value.length < 8) {
         return AppLocalizations.of(context)!.passwordMinLength; // e.g., "Password must be at least 8 characters"
       }
       return null;
     },
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.enterYourNewPassword, // CHANGED
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
      ),
    );
  }
}





