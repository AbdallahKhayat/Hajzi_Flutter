
import 'dart:convert';
import 'dart:io';

import 'package:blogapp/Models/addBlogModel.dart';
import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../CustomWidget/OverlayCard.dart';
import '../Models/addBlogApproval.dart';
import '../NetworkHandler.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this package to decode JWT tokens

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

  NetworkHandler networkHandler = NetworkHandler();
  final storage = FlutterSecureStorage();

  Future<String?> extractUsernameFromToken() async {
    String? token = await storage.read(key: "token");
    if (token != null && token.isNotEmpty) {
      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        return decodedToken["username"];
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
              if (imageFiles.isNotEmpty && _GlobalKey.currentState!.validate()) {
                // Show preview modal
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => OverlayCard(
                    imageFile: imageFiles.first, // Pass the first image for preview
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
                        DropdownMenuItem(value: "general", child: Text("General")),
                        DropdownMenuItem(value: "barbershop", child: Text("Barbershop")),
                        DropdownMenuItem(value: "hospital", child: Text("Hospital")),
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
                        imageFiles.remove(image); // Remove the selected image
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
          // Step 1: Get the username from the token
          String? customerUsername = await extractUsernameFromToken();
          if (customerUsername == null || customerUsername.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unable to retrieve customer username!')),
            );
            return;
          }

          // Step 2: Create AddBlogApproval object
          AddBlogApproval addBlogApproval = AddBlogApproval(
            title: _titleController.text,
            body: _bodyController.text,
            username: customerUsername,
            type: selectedRole ?? "general",
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
              'origin': "http://192.168.88.4:5000",
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': userId,
              'template_params': {
                'user_title': addBlogApproval.title,
                'user_message': addBlogApproval.body,
                'user_name': addBlogApproval.username,
              },
            }),
          );

          print("Email Response: ${emailResponse.body}");

          if (approvalResponse.statusCode == 200 || approvalResponse.statusCode == 201) {
            String blogId = json.decode(approvalResponse.body)["data"];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Blog submitted for approval!')),
            );

            // Step 4: Periodically check approval status
            String status = "pending";
            while (status == "pending") {
              await Future.delayed(Duration(seconds: 5)); // Wait before checking
              var statusResponse = await networkHandler.get("/AddBlogApproval/status/$blogId");

              if (statusResponse is Map<String, dynamic> && statusResponse.containsKey("status")) {
                status = statusResponse["status"];
                print("Approval Status: $status");
              } else {
                print("Error checking approval status: $statusResponse");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error checking approval status'), backgroundColor: Colors.red),
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
                username: addBlogApproval.username,
              );

              var addResponse = await networkHandler.post("/blogpost/Add", addBlogModel.toJson());

              if (addResponse.statusCode == 200 || addResponse.statusCode == 201) {
                String blogId = json.decode(addResponse.body)["data"];

                // Step 6: Upload multiple images
                for (var image in imageFiles) {
                  var imageResponse = await networkHandler.patchImage(
                    "/blogpost/add/coverImages/$blogId",
                    image.path,
                  );

                  if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
                    if(mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to upload image: ${image.name}'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                }
                if(mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Blog approved and published successfully!')),
                );
                if(mounted)
                Navigator.pop(context);
              } else {
                if(mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add blog to blogpost schema'), backgroundColor: Colors.red),
                );
              }
            } else {
              if(mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Blog was not approved by admin'), backgroundColor: Colors.orange),
              );
            }
          } else {
            if(mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit blog for approval'), backgroundColor: Colors.red),
            );
          }
        } else {
          if(mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill in all fields and select at least one image'),
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
