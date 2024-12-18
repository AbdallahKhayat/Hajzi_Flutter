import 'dart:convert';
import 'dart:io';

import 'package:blogapp/Models/addBlogModel.dart';
import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Use only this for LatLng

import '../CustomWidget/OverlayCard.dart';
import '../Models/addBlogApproval.dart';
import '../NetworkHandler.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../Notifications/push_notifications.dart';
import '../SelectLocationPage.dart'; // Ensure this uses google_maps_flutter's LatLng
class AddBlog extends StatefulWidget {
  const AddBlog({super.key});

  @override
  State<AddBlog> createState() => _AddBlogState();
}

class _AddBlogState extends State<AddBlog> {
  final _GlobalKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  ImagePicker _picker = ImagePicker(); // for camera part
  List<XFile> imageFiles = []; // Changed to a list to store multiple images
  IconData? iconPhoto = Icons.image;
  String? selectedRole = "general";
  String email = "";
  String username="";
  String? userRole;
  NetworkHandler networkHandler = NetworkHandler();
  final storage = FlutterSecureStorage();
  double? selectedLat;
  double? selectedLng;

  Future<String?> extractEmailFromToken() async {
    String? token = await storage.read(key: "token");
    if (token != null && token.isNotEmpty) {
      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        return decodedToken["email"];
      } catch (e) {
        print("Error decoding token: $e");
      }
    }
    return null;
  }

  Future<String> checkBlogStatus(String blogId) async {
    var response = await networkHandler.get("/blogpost/status/$blogId");

    if (response is Map<String, dynamic>) {
      if (response.containsKey('status')) {
        return response['status'];
      } else {
        throw Exception("Unexpected response format: $response");
      }
    } else {
      throw Exception("Failed to fetch blog status");
    }
  }


  Future<void> _loadUserRole() async {
    try {
      final role = await storage.read(key: "role");
      final adminEmail = await storage.read(key: "email"); // Admin email stored
      setState(() {
        userRole = role;
        if (userRole == "admin") {
          email = adminEmail ?? ""; // Ensure email is not null
        }
      });
    } catch (e) {
      print("Error loading user role: $e");
    }
  }

  Future<void> _loadUsername() async {
    try {
      // Step 1: Extract email from the token
      String? email = await extractEmailFromToken();
      if (email == null) {
        print("No email found in token.");
        return; // Exit if no email is found
      }

      print("Extracted email from token: $email");

      // Step 2: Make the API call to get the username by email
      final response = await networkHandler.get("/user/searchName/$email");

      print("API Response for username: $response");

      // Step 3: Check if response is a String or a Map
      var responseData;
      if (response is String) {
        responseData = jsonDecode(response); // Decode if it's a string
      } else if (response is Map) {
        responseData = response; // If it's a Map, use it directly
      }

      print("Decoded Response Data: $responseData");

      // Step 4: Extract the 'username' from the response and set it in the state
      setState(() {
        if (responseData != null && responseData["usernames"] != null && responseData["usernames"].isNotEmpty) {
          username = responseData["usernames"][0]; // Extract the first username from the list
          print("Username loaded successfully: $username");
        } else {
          print("No username found for the given email.");
        }
      });
    } catch (e) {
      print("Error loading username: $e");
    }
  }



  @override
  void initState() {
    super.initState(); // Make sure this comes before everything
    Future.microtask(() async {
      await _loadUserRole();
      await _loadUsername(); // Ensure the username is loaded before building UI
    });
  }
  Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    try {
      // Fetch admin emails from the backend
      final adminResponse = await networkHandler.get("/user/getAdmins");

      if (adminResponse != null && adminResponse['adminEmails'] != null) {
        List<dynamic> adminEmails = adminResponse['adminEmails'];

        for (String adminEmail in adminEmails) {
          final response = await networkHandler.post("/notifications/send", {
            "title": title,
            "body": body,
            "recipient": adminEmail, // Send to each admin's email
          });

          final responseBody = json.decode(response.body);
          print("Notification Sent to $adminEmail: ${responseBody['message']}");
        }
      } else {
        print("No admin emails found.");
      }
    } catch (error) {
      print("Error sending notification: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.clear, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Create Post",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (imageFiles.isNotEmpty &&
                  _GlobalKey.currentState!.validate()) {
                // Show preview modal
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => OverlayCard(
                    imageFile: imageFiles.first,
                    // Pass the first image for preview
                    title: _titleController.text,
                  ),
                );
              }
            },
            child: Text(
              "Preview",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _GlobalKey,
          child: SingleChildScrollView(
            child: kIsWeb
                ? Center(
                  child: SizedBox(
                                width: 800,
                    child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Post Title",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.teal,
                                ),
                              ),
                              SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    selectedRole = value;
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                      value: "general", child: Text("General")),
                                  DropdownMenuItem(
                                      value: "barbershop",
                                      child: Text("Barbershop")),
                                  DropdownMenuItem(
                                      value: "hospital", child: Text("Hospital")),
                                ],
                                decoration: InputDecoration(
                                  labelText: "Select Role",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              titleTextField(),
                              SizedBox(height: 20),
                              Text(
                                "Post Content",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.teal,
                                ),
                              ),
                              SizedBox(height: 10),
                              bodyTextField(),
                              SizedBox(height: 20),
                              imagePreview(),
                              SizedBox(height: 30),
                              Center(
                                child: addButton(),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),
                )
                : Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Post Title",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value;
                              });
                            },
                            items: [
                              DropdownMenuItem(
                                  value: "general", child: Text("General")),
                              DropdownMenuItem(
                                  value: "barbershop",
                                  child: Text("Barbershop")),
                              DropdownMenuItem(
                                  value: "hospital", child: Text("Hospital")),
                            ],
                            decoration: InputDecoration(
                              labelText: "Select Role",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          titleTextField(),
                          SizedBox(height: 20),
                          Text(
                            "Post Content",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                          SizedBox(height: 10),
                          bodyTextField(),
                          SizedBox(height: 20),
                          imagePreview(),
                          SizedBox(height: 30),
                          SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () async {
                              final chosenLocation = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SelectLocationPage()),
                              );
                              if (chosenLocation != null) {
                                LatLng loc = chosenLocation;
                                setState(() {
                                  selectedLat = loc.latitude;
                                  selectedLng = loc.longitude;
                                });
                              }

                            },
                            child: Text("Select Shop Location"),
                          ),
                          if (selectedLat != null && selectedLng != null)
                            Text("Location Selected: $selectedLat, $selectedLng"),
                          SizedBox(height: 30),
                          Center(
                            child: addButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget titleTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: TextFormField(
        controller: _titleController,
        validator: (value) {
          if (value!.isEmpty) {
            return "Title can`t be empty";
          } else if (value.length > 100) {
            return "Title can`t be more than 100 characters";
          }
          return null;
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          labelText: "Add Image and Title",
          labelStyle: TextStyle(
            color: Colors.black,
          ),
          prefixIcon: IconButton(
            icon: Icon(
              iconPhoto,
              color: Colors.teal,
            ),
            onPressed: () {
              takeCoverPhotos();
            },
          ),
        ),
        maxLength: 100,
        maxLines: null,
      ),
    );
  }

  Widget bodyTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: _bodyController,
        validator: (value) {
          if (value!.isEmpty) {
            return "Body can`t be empty";
          }
          return null;
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.teal,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          labelText: "Provide Body of Your Blog",
          labelStyle: TextStyle(
            color: Colors.black,
          ),
        ),
        maxLines: null,
      ),
    );
  }

  Widget imagePreview() {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: imageFiles
              .map(
                (image) => Stack(
                  children: [
                    // Display the image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(image.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Add a delete button on top
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            imageFiles
                                .remove(image); // Remove the selected image
                          });
                        },
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        if (imageFiles.isEmpty)
          Text(
            "No images selected",
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget addButton() {
    return InkWell(
      onTap: () async {
        if (_GlobalKey.currentState!.validate() && imageFiles.isNotEmpty) {
          // Step 1: Get the email from the token
          String? customerEmail = await extractEmailFromToken();
          if (customerEmail == null || customerEmail.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unable to retrieve customer email!')),
            );
            return;
          }

          // Step 2: Create AddBlogApproval object
          AddBlogApproval addBlogApproval = AddBlogApproval(
            title: _titleController.text,
            body: _bodyController.text,
            email: customerEmail,
            username: username,
            type: selectedRole ?? "general",
            lat: selectedLat,
            lng: selectedLng,
          );

          // Step 3: Send approval request
          var approvalResponse = await networkHandler.post(
            "/AddBlogApproval/addApproval",
            addBlogApproval.toJson(),
          );

          // Send an email notification
          final serviceId = 'service_lap99wb';
          final templateId = 'template_fon03t7';
          final userId = 'tPJQRVN9PQ2jjZ_6C';
          final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

          final emailResponse = await http.post(
            url,
            headers: {
              'origin': "https://hajzi-6883b1f029cf.herokuapp.com",
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': userId,
              'template_params': {
                'user_title': addBlogApproval.title,
                'user_message': addBlogApproval.body,
                'user_name': addBlogApproval.email,
              },
            }),
          );

          print("Email Response: ${emailResponse.body}");

          // Notify admins about the new blog
          final notificationResponse = await networkHandler.post(
            "/notifications/notifyAdmins/$customerEmail", // Note: Ensure proper string interpolation
            {},
          );

          print("Notification Response Code: ${notificationResponse.statusCode}");
          print("Notification Response Body: ${notificationResponse.body}");

          if (notificationResponse.statusCode == 200) {
            print("Admin notification sent successfully");
            PushNotifications.init();
          } else {
            print("Failed to notify admins");
          }
          if (approvalResponse.statusCode == 200 ||
              approvalResponse.statusCode == 201) {
            String blogId = json.decode(approvalResponse.body)["data"];

            await sendNotification(
              title: "New Shop Approval Request",
              body: "${addBlogApproval.email} has applied for a shop with the title: ${addBlogApproval.title}. Please review it.",
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Blog submitted for approval!')),
            );

            // Step 4: Periodically check approval status
            String status = "pending";
            while (status == "pending") {
              await Future.delayed(
                  Duration(seconds: 5)); // Wait before checking
              var statusResponse =
                  await networkHandler.get("/AddBlogApproval/status/$blogId");

              if (statusResponse is Map<String, dynamic> &&
                  statusResponse.containsKey("status")) {
                status = statusResponse["status"];
                print("Approval Status: $status");
              } else {
                print("Error checking approval status: $statusResponse");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error checking approval status'),
                      backgroundColor: Colors.red),
                );
                return;
              }
            }

            // Step 5: If approved, add to blogpost schema
            if (status == "approved") {
              AddBlogModel addBlogModel = AddBlogModel(
                title: addBlogApproval.title,
                body: addBlogApproval.body,
                status: "approved",
                createdAt: DateTime.now(),
                type: selectedRole ?? "general",
                email: addBlogApproval.email,
                username: addBlogApproval.username,
                lat: selectedLat,
                lng: selectedLng,
              );

              var addResponse = await networkHandler.post(
                  "/blogpost/Add", addBlogModel.toJson());




              if (addResponse.statusCode == 200 ||
                  addResponse.statusCode == 201) {
                String blogId = json.decode(addResponse.body)["data"];

                // Step 6: Upload multiple images
                for (var image in imageFiles) {
                  var imageResponse = await networkHandler.patchImage(
                    "/blogpost/add/coverImages/$blogId",
                    image.path,
                  );

                  if (imageResponse.statusCode != 200 &&
                      imageResponse.statusCode != 201) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to upload image: ${image.name}'),
                            backgroundColor: Colors.red),
                      );
                    return;
                  }
                }
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Blog approved and published successfully!')),
                  );
                if (mounted) Navigator.pop(context);
              } else {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to add blog to blogpost schema'),
                        backgroundColor: Colors.red),
                  );
              }
            } else {
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Blog was not approved by admin'),
                      backgroundColor: Colors.orange),
                );
            }
          } else {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Blog Already Submitted'),
                    backgroundColor: Colors.red),
              );
          }
        } else {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Please fill in all fields and select at least one image'),
                backgroundColor: Colors.orange,
              ),
            );
        }
      },
      child: Center(
        child: Container(
          height: 50,
          width: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.teal,
          ),
          child: Center(
            child: Text(
              "Add Blog",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void takeCoverPhotos() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      setState(() {
        imageFiles = selectedImages;
        iconPhoto = Icons.check_box;
      });
    }
  }
}

// import 'dart:convert';
//
// import 'package:blogapp/Models/addBlogModel.dart';
// import 'package:blogapp/Pages/HomePage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
//
//
// import 'package:image_picker/image_picker.dart';
//
// import '../CustomWidget/OverlayCard.dart';
// import '../Models/addBlogApproval.dart';
// import '../NetworkHandler.dart';
// import 'package:jwt_decoder/jwt_decoder.dart'; // Add this package to decode JWT tokens
//
// class AddBlog extends StatefulWidget {
//   const AddBlog({super.key});
//
//   @override
//   State<AddBlog> createState() => _AddBlogState();
// }
//
// class _AddBlogState extends State<AddBlog> {
//   final _GlobalKey = GlobalKey<FormState>();
//   TextEditingController _titleController = TextEditingController();
//   TextEditingController _bodyController = TextEditingController();
//   ImagePicker _picker = ImagePicker(); //for camera part
//   XFile? imageFile; // to store the image from gallery
//   IconData? iconPhoto =
//       Icons.image; // so u can replace the icon with the photo u fetched
//  String? selectedRole="general";
//
//   NetworkHandler networkHandler = NetworkHandler();
//   final storage = FlutterSecureStorage();
//
//   Future<String?> extractUsernameFromToken() async {
//     String? token = await storage.read(key: "token"); // Read token from secure storage
//     if (token != null && token.isNotEmpty) {
//       try {
//         Map<String, dynamic> decodedToken = JwtDecoder.decode(token); // Decode JWT token
//         print("Decoded Token: $decodedToken"); // Debugging log
//         return decodedToken["username"]; // Adjust based on your token structure
//       } catch (e) {
//         print("Error decoding token: $e"); // Log errors
//       }
//     }
//     return null;
//   }
//
//   Future<String> checkBlogStatus(String blogId) async {
//     var response = await networkHandler.get("/blogpost/status/$blogId");
//
//     if (response is Map<String, dynamic>) {
//       if (response.containsKey('status')) {
//         return response['status']; // Extract the status
//       } else {
//         throw Exception("Unexpected response format: $response");
//       }
//     } else {
//       throw Exception("Failed to fetch blog status");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.teal,
//         elevation: 2,
//         leading: IconButton(
//           icon: Icon(Icons.clear, color: Colors.black),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Text(
//           "Create Post",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//             color: Colors.black,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               if (imageFile?.path != null &&
//                   _GlobalKey.currentState!.validate()) {
//                 // Show preview modal
//                 showModalBottomSheet(
//                   context: context,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                   ),
//                   builder: (context) => OverlayCard(
//                     imageFile: imageFile,
//                     title: _titleController.text,
//                   ),
//                 );
//               }
//             },
//             child: Text(
//               "Preview",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _GlobalKey,
//           child: SingleChildScrollView(
//             child: Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//
//                     Text(
//                       "Post Title",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.teal,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     DropdownButtonFormField<String>(
//                       padding: EdgeInsets.only(bottom:  15),
//                       value: selectedRole,
//                       onChanged: (value) {
//                         setState(() {
//                           selectedRole = value;
//                         });
//                       },
//                       items: [
//                         DropdownMenuItem(value: "general", child: Text("General")),
//                         DropdownMenuItem(value: "barbershop", child: Text("Barbershop")),
//                         DropdownMenuItem(value: "hospital", child: Text("Hospital")),
//                       ],
//                       decoration: InputDecoration(
//                         labelText: "Select Role",
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                     ),
//
//                     SizedBox(height: 10),
//                     titleTextField(),
//                     SizedBox(height: 20),
//                     Text(
//                       "Post Content",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.teal,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     bodyTextField(),
//                     SizedBox(height: 30),
//                     Center(
//                       child: addButton(),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//   Widget titleTextField() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       child: TextFormField(
//         controller: _titleController,
//         validator: (value) {
//           if (value!.isEmpty) {
//             return "Title can`t be empty";
//           } else if (value.length > 100) {
//             return "Title can`t be more than 100 characters";
//           }
//           return null;
//         },
//         decoration: InputDecoration(
//           border: const OutlineInputBorder(
//             borderSide: BorderSide(
//               color: Colors.teal,
//             ),
//           ),
//           focusedBorder: const OutlineInputBorder(
//               //when clicking on textfield
//               borderSide: BorderSide(
//             color: Colors.orange,
//             width: 2,
//           )),
//           labelText: "Add Image and Title",
//           labelStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           prefixIcon: IconButton(
//             icon: Icon(
//               iconPhoto,
//               color: Colors.teal,
//             ),
//             onPressed: () {
//               takeCoverPhoto();
//             },
//           ),
//         ),
//         maxLength: 100,
//         // adds a limiter to textForm
//         maxLines:
//             null, //text automatically goes next line instead of getting cut in row
//       ),
//     );
//   }
//
//   Widget bodyTextField() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 10,
//       ),
//       child: TextFormField(
//         controller: _bodyController,
//         validator: (value) {
//           if (value!.isEmpty) {
//             return "Body can`t be empty";
//           }
//           return null;
//         },
//         decoration: const InputDecoration(
//           border: const OutlineInputBorder(
//             borderSide: BorderSide(
//               color: Colors.teal,
//             ),
//           ),
//           focusedBorder: const OutlineInputBorder(
//               //when clicking on textfield
//               borderSide: BorderSide(
//             color: Colors.orange,
//             width: 2,
//           )),
//           labelText: "Provide Body of Your Blog",
//           labelStyle: const TextStyle(
//             color: Colors.black,
//           ),
//         ),
//         // adds a limiter to textForm
//         maxLines:
//             null, //text automatically goes next line instead of getting cut in row
//       ),
//     );
//   }
//
//
//   Widget addButton() {
//     return InkWell(
//       onTap: () async {
//         if (_GlobalKey.currentState!.validate() && imageFile != null) {
//
//           String? customerUsername = await extractUsernameFromToken();
//
//           if (customerUsername == null || customerUsername.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Unable to retrieve customer username!')),
//             );
//             return;
//           }
//
//             // Create the AddBlogApproval model with correct data
//           var response = await networkHandler.get("/profile/checkProfile", );
//           print("User Info: $response"); // Debug log to see the response
//           AddBlogApproval addBlogApproval = AddBlogApproval(
//             title: _titleController.text,
//             body: _bodyController.text,
//             username: customerUsername, // Use the actual username
//             type: selectedRole ?? "general", // Use the selected role
//           );
//
//           // Step 1: Add to AddBlogApproval schema
//           var approvalResponse = await networkHandler.post(
//             "/AddBlogApproval/addApproval",
//             addBlogApproval.toJson(),
//           );
//
//           final serviceId = 'service_lap99wb';
//           final templateId = 'template_fon03t7';
//           final userId = 'tPJQRVN9PQ2jjZ_6C';
//
//           final url=Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
//           final response2=await http.post(url,
//             headers: {
//             'origin':"http://192.168.88.4:5000",
//               'Content-Type': 'application/json',
//             },
//             body:json.encode({
//             'service_id':serviceId,
//               'template_id':templateId,
//               'user_id':userId,
//               'template_params':{
//                 'user_title':addBlogApproval.title,
//                 'user_message':addBlogApproval.body,
//                 'user_name':addBlogApproval.username,
//               }
//
//             }),
//           );
//
//           print(response2.body);
//
//
//           if (approvalResponse.statusCode == 200||approvalResponse.statusCode == 201) {
//             String blogId = json.decode(approvalResponse.body)["data"]; // Blog ID
//             print("Blog ID: $blogId");
//             print(approvalResponse.body);
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Blog submitted for approval!')),
//             );
//
//             // Step 2: Periodically check status
//             String status = "pending";
//             while (status == "pending") {
//
//               await Future.delayed(Duration(seconds: 5)); // Wait before re-checking
//
//               // Get the status response as a map, no need to access .body
//               var statusResponse = await networkHandler.get("/AddBlogApproval/status/$blogId");
//
//               // Debug print the entire response (which is a Map, not a Response object)
//
//                print("Status Response: $statusResponse");
//
//               // Now you can directly check the status from the Map
//               if (statusResponse is Map<String, dynamic> && statusResponse.containsKey("status")) {
//                 status = statusResponse["status"]; // Get the status directly
//                 if(mounted) {
//                   print("Updated Status: $status");
//                 }// Debug log
//               } else {
//                 if(mounted) {
//                   print(
//                       "Error fetching status: ${statusResponse}"); // Debug log
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Error checking approval status'),
//                         backgroundColor: Colors.red),
//                   );
//                 }
//                 return; // Exit on error
//               }
//             }
//
//
//             // Step 3: If approved, add to blogpost schema
//             if (status == "approved") {
//               AddBlogModel addBlogModel = AddBlogModel(
//                 title: addBlogApproval.title,
//                 body: addBlogApproval.body,
//                 status: "approved",
//                 createdAt: DateTime.now(),
//                 type: selectedRole??"general",
//                 username: addBlogApproval.username, // Use the username from AddBlogApproval
//               );
//
//               var addResponse = await networkHandler.post("/blogpost/Add", addBlogModel.toJson());
//               print("Add Blog Response: ${addResponse.statusCode}");
//
//               if (addResponse.statusCode == 200 || addResponse.statusCode == 201) {
//                 String id=json.decode(addResponse.body)["data"];
//                 var imageResponse = await networkHandler.patchImage(
//                   "/blogpost/add/coverImage/$id",
//                   imageFile!.path,
//                 );
//                 print("Image Upload Response: ${imageResponse.statusCode}");
//
//                 if (imageResponse.statusCode == 200 || imageResponse.statusCode == 201) {
//                   if(mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(
//                           'Blog approved and published successfully!')),
//                     );
//
//                     Navigator.pop(context);
//                   }
//                 } else {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Failed to upload image'), backgroundColor: Colors.red),
//                     );
//                   }
//                 }
//               } else {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Failed to add blog to blogpost schema'), backgroundColor: Colors.red),
//                   );
//                 }
//               }
//
//
//           } else {
//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Blog was not approved by admin'), backgroundColor: Colors.orange),
//                 );
//               }
//             }
//
//           } else {
//             if(mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Blog has been already submited'),
//                     backgroundColor: Colors.red),
//               );
//             }
//           }
//         } else {
//           if(mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(
//                   'Please fill in all fields and select an image'),
//                   backgroundColor: Colors.orange),
//             );
//           }
//         }
//       },
//       child: Center(
//         child: Container(
//           height: 50,
//           width: 170,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             color: Colors.teal,
//           ),
//           child: const Center(
//             child: Text(
//               "Add Blog",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<String> validateBlog(AddBlogModel blog) async {
//     // Make an API call to validate the blog (if available)
//     var response = await networkHandler.post("/blogpost/validate", blog.toJson());
//
//     if (response.statusCode == 200) {
//       var data = json.decode(response.body);
//       return data["status"]; // Assuming the API returns 'approved' or 'pending'
//     } else {
//       return "rejected"; // Default to rejected if validation fails
//     }
//   }
//
//
//   void takeCoverPhoto() async {
//     final XFile? coverPhoto = await _picker.pickImage(
//         source: ImageSource.gallery); // Fetch the image from Gallery
//     setState(() {
//       imageFile = coverPhoto; // No casting needed
//       iconPhoto = Icons
//           .check_box; // to change the icon to check_box icon when image is fetched
//     });
//   }
// }
