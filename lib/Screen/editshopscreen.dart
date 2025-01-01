import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Models/addBlogModel.dart';
import '../NetworkHandler.dart';
import 'package:image_picker/image_picker.dart';

import '../Notifications/push_notifications.dart';
import '../constants.dart';

class EditShopScreen extends StatefulWidget {
  final AddBlogModel addBlogModel;
  final NetworkHandler networkHandler;

  const EditShopScreen({
    super.key,
    required this.addBlogModel,
    required this.networkHandler,
  });
//hello
  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? selectedRole;
  File? previewImageFile; // For preview image replacement
  List<File> newCoverImages = []; // For new slideshow images
  List<String> existingCoverImages = [];
  final ImagePicker _picker = ImagePicker();
  NetworkHandler networkHandler=NetworkHandler();

  @override
  void initState() {
    super.initState();
    // Pre-fill form fields with existing data
    _titleController.text = widget.addBlogModel.title ?? "";
    _bodyController.text = widget.addBlogModel.body ?? "";
    selectedRole = widget.addBlogModel.type;
    existingCoverImages = widget.addBlogModel.coverImages ?? [];
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
  Future<void> _submitChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        AddBlogModel updatedBlog = AddBlogModel(
          id: widget.addBlogModel.id, // Retain the same blog ID
          title: _titleController.text,
          body: _bodyController.text,
          type: selectedRole ?? "general",
          createdAt: widget.addBlogModel.createdAt,
          status: "approved", // Keep the status
          email: widget.addBlogModel.email,
        );

        // Update text fields on the server
        var response = await widget.networkHandler.patch(
          "/blogpost/update/${widget.addBlogModel.id}",
          updatedBlog.toJson(),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Update the preview image if a new one was selected
          if (previewImageFile != null) {
            await widget.networkHandler.patchImage(
              "/blogpost/update/previewImage/${widget.addBlogModel.id}",
              previewImageFile!.path,
            );
          }

          // Upload new slideshow images if added
          if (newCoverImages.isNotEmpty) {
            for (var image in newCoverImages) {
              await widget.networkHandler.patchImage(
                "/blogpost/add/coverImages/${widget.addBlogModel.id}",
                image.path,
              );
            }
          }

          final notificationResponse = await networkHandler.post(
            "/notifications/notifyAdmins/updateShop/${widget.addBlogModel.email}/${widget.addBlogModel.id}", // Note: Ensure proper string interpolation
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


          await sendNotification(
            title: "Shop Modifications",
            body: "${widget.addBlogModel.email} has modified on his shop with the title: ${widget.addBlogModel.title}...",
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Blog updated successfully!")),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception("Failed to update blog");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating blog: $e")),
          );
        }
      }
    }
  }

  void _pickPreviewImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        previewImageFile = File(pickedImage.path);
      });
    }
  }

  void _pickNewCoverImages() async {
    final List<XFile>? pickedImages = await _picker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        newCoverImages = pickedImages.map((image) => File(image.path)).toList();
      });
    }
  }

  void _removeExistingCoverImage(String imageUrl) async {
    try {
      final response = await widget.networkHandler.delete2(
        "/blogpost/remove/coverImage/${widget.addBlogModel.id}",
        body: jsonEncode({"imageUrl": imageUrl}), // Pass the imageUrl in the request body
      );

      if (response['message'] == "Cover image removed successfully") {
        setState(() {
          existingCoverImages.remove(imageUrl); // Remove from the UI
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove image")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the platform is web
    bool isWeb = kIsWeb;

    // Define maximum width for web layout
    double maxWidth = 800;

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
        title: const Text(
          "Edit Shop",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: isWeb
                ? BoxConstraints(
              maxWidth: maxWidth,
            )
                : BoxConstraints(), // No constraints on mobile
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dropdown for Role Selection
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                                value: "general", child: Text("General")),
                            DropdownMenuItem(
                                value: "barbershop", child: Text("Barbershop")),
                            DropdownMenuItem(
                                value: "hospital", child: Text("Hospital")),
                          ],
                          decoration: const InputDecoration(labelText: "Type"),
                        ),
                        const SizedBox(height: 24),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: "Title",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Title can't be empty";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Body Field
                        TextFormField(
                          controller: _bodyController,
                          decoration: const InputDecoration(
                            labelText: "Body",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Body can't be empty";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Preview Image Section
                        Text(
                          "Preview Image",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: previewImageFile != null
                                ? Image.file(
                              previewImageFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : widget.addBlogModel.previewImage != null
                                ? Image.network(
                              widget.networkHandler
                                  .formater2(widget.addBlogModel.previewImage!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : const Center(
                              child: Text(
                                "No preview image selected",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Button to Change Preview Image (Centered)
                        Align(
                          alignment: Alignment.center,
                          child: ValueListenableBuilder<Color>(
                            valueListenable: appColorNotifier,
                            builder: (context, color, child) {
                              return TextButton(
                                onPressed: _pickPreviewImage,
                                child: const Text("Change Preview Image"),
                                style: ButtonStyle(
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(color),
                                  padding: MaterialStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Slideshow Images Section
                        Text(
                          "Slideshow Images",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...existingCoverImages.map(
                                  (imageUrl) => Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          widget.networkHandler
                                              .formater2(imageUrl),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        onPressed: () =>
                                            _removeExistingCoverImage(imageUrl),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...newCoverImages.map(
                                  (imageFile) => Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: FileImage(imageFile),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        onPressed: () =>
                                            _removeExistingCoverImage(imageFile as String),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Button to Add New Slideshow Images (Centered)
                        Align(
                          alignment: Alignment.center,
                          child: ValueListenableBuilder<Color>(
                            valueListenable: appColorNotifier,
                            builder: (context, color, child) {
                              return TextButton(
                                onPressed: _pickNewCoverImages,
                                child: const Text("Add New Images"),
                                style: ButtonStyle(
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(color),
                                  padding: MaterialStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Changes Button (Aligned to Right)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _submitChanges,
                            child: const Text("Save Changes"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
