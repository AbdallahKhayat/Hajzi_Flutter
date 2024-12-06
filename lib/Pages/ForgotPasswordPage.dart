import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  String buttonText = "Verify Email";
  bool isVerified = false;
  String? errorText;

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
            'reset_link': 'https://quiet-scrubland-10088-12201191fd7c.herokuapp.com/user/verify/$email',
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
      throw Exception('Error while sending email: $e');
    }
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
      const SnackBar(content: Text('Password updated successfully!')),
    );

    // Reset local state
    setState(() {
      isVerified = false;
      buttonText = "Verify Email"; // Reset button text
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
            colors: [Colors.white, Colors.green[200]!],
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
                const Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.key,
                  size: 60,
                  color: Colors.black,
                ),
                const SizedBox(height: 20),
                emailTextField(),
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
                              isVerified = true;
                              buttonText = "Update Password";
                            });
                          } else {
                            // Send verification email
                            await sendVerificationEmail(_emailController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please verify your email!'),
                              ),
                            );
                          }
                        } else {
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
    return TextFormField(
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
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
      ),
    );
  }
}




















// import 'dart:convert';
// import 'package:blogapp/NetworkHandler.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import 'EmailSignInPage.dart';
//
// class ForgotPasswordPage extends StatefulWidget {
//   final Function(Locale locale) setLocale;
//
//   const ForgotPasswordPage({Key? key, required this.setLocale})
//       : super(key: key);
//
//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }
//
// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final _globalKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool visible = true;
//   bool circular = false;
//   String? errorText;
// NetworkHandler networkHandler=NetworkHandler();
//   Future<void> sendVerificationEmail(String email) async {
//     final serviceId = 'service_8eg3t9i'; // Replace with your EmailJS Service ID
//     final templateId = 'template_xcrzqrq'; // Replace with your EmailJS Template ID
//     final userId = '3QhZNOXQgjXaKjDRk'; // Replace with your EmailJS User ID
//
//     final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json','origin': 'http://localhost'},
//       body: json.encode({
//         'service_id': serviceId,
//         'template_id': templateId,
//         'user_id': userId,
//         'template_params': {
//           'from_name':"Hajzi Team",
//           'to_name': email, // Matches your template parameter
//           'to_email': email, // Matches your template parameter
//           'reset_link': 'http://192.168.88.2:5000/user/verify/$email',
//         },
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       print('Verification email sent successfully!');
//     } else {
//       throw Exception('Failed to send email: ${response.body}');
//     }
//   }
//
//   Future<bool> isVerified(String email) async {
//     final response = await networkHandler.get2E('/user/isVerified/$email', requireAuth: false);
//
//     print("Raw Response from /isVerified: $response");
//
//     if (response != null && response['verified'] != null) {
//       print("Verification status from response: ${response['verified']}");
//       return response['verified'] == true;
//     } else {
//       print("Unexpected response: $response");
//       throw Exception('Failed to fetch verification status');
//     }
//   }
//
//   Future<void> updatePassword(String email, String password) async {
//     final response = await networkHandler.patch2E(
//       '/user/update/$email',
//       {'password': password},
//       requireAuth: false
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception('Failed to update password');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.white, Colors.green[200]!],
//             begin: const FractionalOffset(0.0, 1.0),
//             end: const FractionalOffset(0.0, 1.0),
//             stops: [0.0, 1.0],
//             tileMode: TileMode.repeated,
//           ),
//         ),
//         child: Form(
//           key: _globalKey,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "Update Password",
//                   style: TextStyle(
//                     fontSize: 30,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 2,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Icon(
//                   Icons.key,
//                   size: 60,
//                   color: Colors.black,
//                 ),
//                 const SizedBox(height: 20),
//                 emailTextField(),
//                 const SizedBox(height: 15),
//                 passwordTextField(),
//                 const SizedBox(height: 20),
//                 InkWell(
//                   onTap: () async {
//                     if (_globalKey.currentState!.validate()) {
//                       setState(() {
//                         circular = true;
//                       });
//
//                       try {
//                         // Check if the user is already verified
//                         bool verified = await isVerified(_emailController.text);
//
//                         print(verified);
//
//                         if (verified==true) {
//                           // If already verified, directly update the password
//                           try {
//                             await updatePassword(
//                               _emailController.text,
//                               _passwordController.text,
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Password updated successfully!'),
//                               ),
//                             );
//
//                             // Navigate to EmailSignInPage
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => EmailSignInPage(
//                                   setLocale: widget.setLocale, // Pass setLocale if required
//                                 ),
//                               ),
//                             );
//                           } catch (e) {
//                             setState(() {
//                               errorText = e.toString();
//                             });
//                           }
//                         } else {
//                           // If not verified, send the verification email
//                           try {
//                             await sendVerificationEmail(_emailController.text);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Verification email sent! Please check your inbox.'),
//                               ),
//                             );
//                           } catch (e) {
//                             setState(() {
//                               errorText = e.toString();
//                             });
//                           }
//                         }
//                       } catch (e) {
//                         setState(() {
//                           errorText = e.toString();
//                         });
//                       } finally {
//                         setState(() {
//                           circular = false;
//                         });
//                       }
//                     }
//                   },
//
//
//                   child: Container(
//                     width: 170,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       gradient: LinearGradient(
//                         colors: [Colors.teal.shade300, Colors.green.shade300],
//                       ),
//                     ),
//                     child: Center(
//                       child: circular
//                           ? const CircularProgressIndicator()
//                           : const Text(
//                         "Update Password",
//                         style: TextStyle(
//                             fontSize: 17, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget emailTextField() {
//     return TextFormField(
//       controller: _emailController,
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Email can’t be empty!';
//         }
//         if (!value.contains("@")) {
//           return 'Invalid email!';
//         }
//         return null;
//       },
//       decoration: InputDecoration(
//         hintText: "Enter your email",
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.9),
//         prefixIcon: const Icon(Icons.email, color: Colors.black),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Colors.blue, width: 2),
//         ),
//       ),
//     );
//   }
//
//   Widget passwordTextField() {
//     return TextFormField(
//       controller: _passwordController,
//       obscureText: visible,
//       decoration: InputDecoration(
//         hintText: "Enter your new password",
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.9),
//         prefixIcon: const Icon(Icons.lock, color: Colors.black),
//         suffixIcon: IconButton(
//           icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
//           onPressed: () {
//             setState(() {
//               visible = !visible;
//             });
//           },
//         ),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Colors.blue, width: 2),
//         ),
//       ),
//     );
//   }
// }
