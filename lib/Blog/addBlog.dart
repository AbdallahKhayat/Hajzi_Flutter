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
import '../SelectLocationPage.dart';
import '../constants.dart'; // Ensure this uses google_maps_flutter's LatLng
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  List<Uint8List> _webImages = [];
  IconData? iconPhoto = Icons.image;
  String? selectedRole = "general";
  String email = "";
  String username = "";
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

  // Function to upload preview image to BlogPost
  Future<void> uploadPreviewImageToBlogPost(String blogId) async {
    if (kIsWeb && _webImages.isNotEmpty) {
      // The first image is the preview
      final imageBytes = _webImages.first;
      final imageResponse = await networkHandler.patchImageWeb(
        "/blogpost/update/previewImage/$blogId",
        imageBytes,
      );
      if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
        throw Exception("Preview image upload (web) failed.");
      }
    } else if (!kIsWeb && imageFiles.isNotEmpty) {
      // Mobile
      final imageFile = imageFiles.first;
      final imageResponse = await networkHandler.patchImage(
        "/blogpost/update/previewImage/$blogId",
        imageFile.path,
      );
      if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
        throw Exception("Preview image upload (mobile) failed.");
      }
    }
  }

// Function to upload cover images to BlogPost
  Future<void> uploadCoverImagesToBlogPost(String blogId) async {
    // For web
    if (kIsWeb && _webImages.length > 1) {
      // Start from index 1 for cover images
      for (int i = 1; i < _webImages.length; i++) {
        final imageBytes = _webImages[i];
        final imageResponse = await networkHandler.patchImageWeb(
          "/blogpost/add/coverImages/$blogId",
          imageBytes,
        );
        if (imageResponse.statusCode != 200 &&
            imageResponse.statusCode != 201) {
          throw Exception("Cover image #$i (web) failed to upload.");
        }
      }
    }

    // For mobile
    else if (!kIsWeb && imageFiles.length > 1) {
      for (int i = 1; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final imageResponse = await networkHandler.patchImage(
          "/blogpost/add/coverImages/$blogId",
          imageFile.path,
        );
        if (imageResponse.statusCode != 200 &&
            imageResponse.statusCode != 201) {
          throw Exception("Cover image #$i (mobile) failed to upload.");
        }
      }
    }
  }

  /// A fun, stylish loading dialog method.
  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss the dialog manually
      builder: (BuildContext context) {
        return Dialog(
          elevation: 10,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon at the top
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt,
                      size: 36,
                      color: appColorNotifier.value,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Message text
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Circular progress indicator
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(appColorNotifier.value),
                ),
                const SizedBox(height: 20),
                // Optional tagline
                Text(
                  AppLocalizations.of(context)!.pleaseWaitMagicHappening,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        if (responseData != null &&
            responseData["usernames"] != null &&
            responseData["usernames"].isNotEmpty) {
          username = responseData["usernames"]
          [0]; // Extract the first username from the list
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

  // Updated function to upload a preview image using patchImage
  Future<void> uploadPreviewImage(String blogId) async {
    if (kIsWeb && _webImages.isNotEmpty) {
      final imageBytes = _webImages.first;
      final imageResponse = await networkHandler.patchImageWeb(
        "/AddBlogApproval/previewImage/$blogId",
        imageBytes,
      );
      if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
        throw Exception("Preview image upload (web) to approval failed.");
      }
    } else if (!kIsWeb && imageFiles.isNotEmpty) {
      final imageFile = imageFiles.first;
      final imageResponse = await networkHandler.patchImage(
        "/AddBlogApproval/previewImage/$blogId",
        imageFile.path,
      );
      if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
        throw Exception("Preview image upload (mobile) to approval failed.");
      }
    }
  }

// Updated function to upload cover images using patchImage
  Future<void> uploadCoverImages(String blogId) async {
    if (kIsWeb && _webImages.length > 1) {
      for (int i = 1; i < _webImages.length; i++) {
        final bytes = _webImages[i];
        final imageResponse = await networkHandler.patchImageWeb(
          "/AddBlogApproval/coverImages/$blogId",
          bytes,
        );
        if (imageResponse.statusCode != 200 &&
            imageResponse.statusCode != 201) {
          throw Exception("Cover image #$i (web) to approval failed.");
        }
      }
    } else if (!kIsWeb && imageFiles.length > 1) {
      for (int i = 1; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final imageResponse = await networkHandler.patchImage(
          "/AddBlogApproval/coverImages/$blogId",
          file.path,
        );
        if (imageResponse.statusCode != 200 &&
            imageResponse.statusCode != 201) {
          throw Exception("Cover image #$i (mobile) to approval failed.");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: ValueListenableBuilder<Color>(
          valueListenable: appColorNotifier,
          builder: (context, appColor, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor.withOpacity(1), appColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.clear, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.createPost,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // We have two separate lists, but let's unify them:
              if ((!kIsWeb && imageFiles.isNotEmpty) ||
                  (kIsWeb && _webImages.isNotEmpty)) {
                if (_GlobalKey.currentState!.validate()) {
                  // Show preview modal with the "first" image
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => OverlayCard(
                      // If you have a web image, pass it here:
                      webImage: kIsWeb && _webImages.isNotEmpty ? _webImages.first : null,
                      // If you have a mobile file, pass it here:
                      imageFile: !kIsWeb && imageFiles.isNotEmpty
                          ? XFile(imageFiles.first.path)
                          : null,
                      title: _titleController.text,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.preview,
              style: const TextStyle(
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
                        ValueListenableBuilder<Color>(
                          valueListenable: appColorNotifier,
                          builder: (context, appColor, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    appColor.withOpacity(1),
                                    appColor
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                AppLocalizations.of(context)!.postTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors
                                      .white, // Required but overridden by the shader
                                ),
                              ),
                            );
                          },
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
                              value: "general",
                              child: Text(
                                  AppLocalizations.of(context)!.general),
                            ),
                            DropdownMenuItem(
                              value: "barbershop",
                              child: Text(AppLocalizations.of(context)!
                                  .barbershop),
                            ),
                            DropdownMenuItem(
                              value: "hospital",
                              child: Text(
                                  AppLocalizations.of(context)!.hospital),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText:
                            AppLocalizations.of(context)!.selectRole,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        titleTextField(),
                        SizedBox(height: 20),
                        ValueListenableBuilder<Color>(
                          valueListenable: appColorNotifier,
                          builder: (context, appColor, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    appColor.withOpacity(1),
                                    appColor
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                AppLocalizations.of(context)!.postContent,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors
                                      .white, // Required but overridden by the shader
                                ),
                              ),
                            );
                          },
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
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const SelectLocationPage()),
                            );
                            if (chosenLocation != null) {
                              LatLng loc = chosenLocation;
                              setState(() {
                                selectedLat = loc.latitude;
                                selectedLng = loc.longitude;
                              });
                            }
                          },
                          child: ValueListenableBuilder<Color>(
                            valueListenable: appColorNotifier,
                            builder: (context, appColor, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      appColor.withOpacity(1),
                                      appColor
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .selectShopLocation,
                                  style: const TextStyle(
                                    color: Colors
                                        .white, // Required but overridden by the shader
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (selectedLat != null && selectedLng != null)
                          Text(
                            "${AppLocalizations.of(context)!
                                .locationSelected}: $selectedLat, $selectedLng",
                          ),
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
                    ValueListenableBuilder<Color>(
                      valueListenable: appColorNotifier,
                      builder: (context, appColor, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [appColor.withOpacity(1), appColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.postTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors
                                  .white, // Required but overridden by the shader
                            ),
                          ),
                        );
                      },
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
                          value: "general",
                          child:
                          Text(AppLocalizations.of(context)!.general),
                        ),
                        DropdownMenuItem(
                          value: "barbershop",
                          child: Text(
                              AppLocalizations.of(context)!.barbershop),
                        ),
                        DropdownMenuItem(
                          value: "hospital",
                          child: Text(
                              AppLocalizations.of(context)!.hospital),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText:
                        AppLocalizations.of(context)!.selectRole,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    titleTextField(),
                    SizedBox(height: 20),
                    ValueListenableBuilder<Color>(
                      valueListenable: appColorNotifier,
                      builder: (context, appColor, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [appColor.withOpacity(1), appColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.postContent,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors
                                  .white, // Required but overridden by the shader
                            ),
                          ),
                        );
                      },
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
                          MaterialPageRoute(
                              builder: (context) =>
                              const SelectLocationPage()),
                        );
                        if (chosenLocation != null) {
                          LatLng loc = chosenLocation;
                          setState(() {
                            selectedLat = loc.latitude;
                            selectedLng = loc.longitude;
                          });
                        }
                      },
                      child: ValueListenableBuilder<Color>(
                        valueListenable: appColorNotifier,
                        builder: (context, appColor, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  appColor.withOpacity(1),
                                  appColor
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              AppLocalizations.of(context)!
                                  .selectShopLocation,
                              style: const TextStyle(
                                color: Colors
                                    .white, // Required but overridden by the shader
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (selectedLat != null && selectedLng != null)
                      Text(
                        "${AppLocalizations.of(context)!
                            .locationSelected}: $selectedLat, $selectedLng",
                      ),
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
            return AppLocalizations.of(context)!.titleCannotBeEmpty;
          } else if (value.length > 100) {
            return AppLocalizations.of(context)!.titleCannotExceed100Chars;
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
            labelText: AppLocalizations.of(context)!.addImageAndTitle,
            labelStyle: TextStyle(
              color: Colors.black,
            ),
            prefixIcon: ValueListenableBuilder<Color>(
              valueListenable: appColorNotifier,
              builder: (context, appColor, child) {
                return IconButton(
                  icon: Icon(
                    iconPhoto, // Replace with your icon variable
                    color: appColor, // Dynamic color
                  ),
                  onPressed: () {
                    takeCoverPhotos();
                  },
                );
              },
            )),
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
            return AppLocalizations.of(context)!.bodyCannotBeEmpty;
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
          labelText: AppLocalizations.of(context)!.provideBlogBody,
          labelStyle: TextStyle(
            color: Colors.black,
          ),
        ),
        maxLines: null,
      ),
    );
  }

  Widget imagePreview() {
    // On mobile => _mobileImages
    // On web => _webImages
    //
    // We'll unify them in a single "preview" so you can see them in a Wrap.
    final imagesCount = kIsWeb ? _webImages.length : imageFiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(imagesCount, (index) {
            return _buildSingleImagePreview(index);
          }),
        ),
        if (imagesCount == 0)
          Text(
            AppLocalizations.of(context)!.noImagesSelected,
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildSingleImagePreview(int index) {
    if (kIsWeb) {
      // Web
      final bytes = _webImages[index];
      return Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _webImages.removeAt(index);
                });
              },
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      // Mobile
      final xfile = imageFiles[index];
      return Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(xfile.path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  imageFiles.removeAt(index);
                });
              },
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget addButton() {
    return InkWell(
      onTap: () async {
        if (_GlobalKey.currentState!.validate() && imageFiles.isNotEmpty ||
            _webImages.isNotEmpty) {
          // Show confirmation dialog before proceeding
          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.confirmSubmission),
                content:
                Text(AppLocalizations.of(context)!.areYouSureSubmitShop),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // Cancel
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true), // Confirm
                    child: Text(
                      AppLocalizations.of(context)!.submit,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
          if (confirm == true) {
            // -------------------------------------------------------------
            // NEW CODE: Show the loading dialog immediately before upload
            // -------------------------------------------------------------
            // "Your Shop is Uploading..."
            showLoadingDialog(
                context, AppLocalizations.of(context)!.shopUploading);
            // Step 1: Get the email from the token
            String? customerEmail = await extractEmailFromToken();
            if (customerEmail == null || customerEmail.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to retrieve customer email!')),
              );
              return;
            }

            var shopCountResponse =
            await networkHandler.get("/blogpost/countUserShops");
            int userShopsCount = 0;
            if (shopCountResponse is Map<String, dynamic> &&
                shopCountResponse.containsKey("shopCount")) {
              userShopsCount = shopCountResponse["shopCount"];
            }
            if (userShopsCount == 0) {
              // =========== Directly create in BlogPost ===========
              AddBlogModel newShop = AddBlogModel(
                title: _titleController.text,
                body: _bodyController.text,
                status: "approved",
                // or "published" if you prefer
                createdAt: DateTime.now(),
                type: selectedRole ?? "general",
                email: customerEmail,
                username: username,
                lat: selectedLat,
                lng: selectedLng,
              );

              var addResponse =
              await networkHandler.post("/blogpost/Add", newShop.toJson());

              if (addResponse.statusCode == 200 ||
                  addResponse.statusCode == 201) {
                String newBlogId = json.decode(addResponse.body)["data"];

                // Upload images to the new BlogPost
                // 1) Upload preview
                await uploadPreviewImageToBlogPost(newBlogId);
                // 2) Upload covers
                await uploadCoverImagesToBlogPost(newBlogId);

                // close loading dialog
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                // Show success
                if (mounted) {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.success,
                            ),
                          ],
                        ),
                        //,
                        //First shop created successfully!
                        content: Text(AppLocalizations.of(context)!
                            .shopCreatedSuccessfully),
                        actions: <Widget>[
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.ok,
                                style: const TextStyle(color: Colors.black)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                }
              } else {
                Navigator.of(context).pop(); // close loading
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.failedToCreateShop),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
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
              final url =
              Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

              final emailResponse = await http.post(
                url,
                headers: {
                  'origin': "https://hajziapp-98152e888858.herokuapp.com",
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
                "/notifications/notifyAdmins/$customerEmail",
                // Note: Ensure proper string interpolation
                {},
              );

              print(
                  "Notification Response Code: ${notificationResponse
                      .statusCode}");
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
                  body:
                  "${addBlogApproval
                      .email} has applied for a shop with the title: ${addBlogApproval
                      .title}. Please review it.",
                );

                // 1) Upload preview to approval
                await uploadPreviewImage(blogId);
                // 2) Upload covers to approval
                await uploadCoverImages(blogId);

                // -------------------------------------------------------------
                // CLOSE LOADING DIALOG before showing next dialog
                // -------------------------------------------------------------
                Navigator.of(context).pop(); // close loading dialog
                Navigator.of(context).pop();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.submissionSuccessful,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        //'Your shop has been submitted for approval!'
                        content: Text(AppLocalizations.of(context)!
                            .shopSubmittedForApproval),

                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text(
                              AppLocalizations.of(context)!.ok,
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }

                // Step 4: Periodically check approval status
                String status = "pending";
                while (status == "pending") {
                  await Future.delayed(
                      Duration(seconds: 5)); // Wait before checking
                  var statusResponse = await networkHandler
                      .get("/AddBlogApproval/status/$blogId");

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
                    String newBlogId = json.decode(addResponse.body)["data"];
                    print("New BlogPost ID: $newBlogId");

                    // Step 6: Upload preview image to BlogPost

                      await uploadPreviewImageToBlogPost(newBlogId);
                      await uploadCoverImagesToBlogPost(newBlogId);


                    if (mounted) Navigator.pop(context);
                    if (mounted) {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.success),
                              ],
                            ),
                            //Shop approved and published successfully!
                            content: Text(AppLocalizations.of(context)!
                                .shopApprovedAndPublished),
                            actions: <Widget>[
                              TextButton(
                                child: Text(
                                  AppLocalizations.of(context)!.ok,
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } else {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('Failed to add blog to blogpost schema'),
                            backgroundColor: Colors.red),
                      );
                  }
                } else {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            AppLocalizations.of(context)!.approvalPending,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                              AppLocalizations.of(context)!.shopNotApproved),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text(
                                AppLocalizations.of(context)!.ok,
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              } else {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.submissionError,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                            AppLocalizations.of(context)!.blogAlreadySubmitted),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text(
                              AppLocalizations.of(context)!.ok,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            }
          } else {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.fillAllFieldsAndSelectImage,
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
          }
        }
      },
      child: Center(
          child: ValueListenableBuilder<Color>(
            valueListenable: appColorNotifier,
            builder: (context, appColor, child) {
              return Container(
                height: 50,
                width: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [appColor.withOpacity(1), appColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.addShop,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          )),
    );
  }

  Future<void> takeCoverPhotos() async {
    final selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      // Clear existing images
      imageFiles.clear();
      _webImages.clear();

      if (kIsWeb) {
        // On Web, read each image as bytes
        for (XFile xfile in selectedImages) {
          final bytes = await xfile.readAsBytes();
          _webImages.add(bytes);
        }
      } else {
        // On Mobile, just store the XFile objects
        for (XFile xfile in selectedImages) {
          imageFiles.add(
              xfile); // <-- FIXED: add the entire XFile, not xfile.path
        }
      }

      setState(() {
        iconPhoto = Icons.check_box; // Update the icon
      });
    }
  }


}
class OverlayCard extends StatelessWidget {
  final XFile? imageFile;       // still for mobile
  final Uint8List? webImage;    // new for web
  final String title;

  const OverlayCard({
    Key? key,
    this.imageFile,
    this.webImage,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // For example
      height: 300,
      child: Column(
        children: [
          // The image
          if (webImage != null)
            Image.memory(
              webImage!,
              fit: BoxFit.cover,
              height: 250,
            )
          else if (imageFile != null)
            Image.file(
              File(imageFile!.path),
              fit: BoxFit.cover,
              height: 250,
            )
          else
            const Text("No image selected"),
          const SizedBox(height: 10),
          // The title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
