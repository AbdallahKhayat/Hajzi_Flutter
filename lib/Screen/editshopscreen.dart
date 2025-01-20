import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Models/addBlogModel.dart';
import '../NetworkHandler.dart';
import 'package:image_picker/image_picker.dart';

import '../Notifications/push_notifications.dart';
import '../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  NetworkHandler networkHandler = NetworkHandler();
  Uint8List? _previewImageBytes; // Web (in-memory bytes)
  List<Uint8List> _newCoverImageBytes = []; // Web
  @override
  void initState() {
    super.initState();
    // Pre-fill form fields with existing data
    _titleController.text = widget.addBlogModel.title ?? "";
    _bodyController.text = widget.addBlogModel.body ?? "";
    selectedRole = widget.addBlogModel.type;
    existingCoverImages = widget.addBlogModel.coverImages ?? [];
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
      // Show the loading dialog before starting network operations
      showLoadingDialog(context, AppLocalizations.of(context)!.updatingShop);
      try {
        AddBlogModel updatedBlog = AddBlogModel(
          id: widget.addBlogModel.id,
          // Retain the same blog ID
          title: _titleController.text,
          body: _bodyController.text,
          type: selectedRole ?? "general",
          createdAt: widget.addBlogModel.createdAt,
          status: "approved",
          // Keep the status
          email: widget.addBlogModel.email,
        );

        // Update text fields on the server
        var response = await widget.networkHandler.patch(
          "/blogpost/update/${widget.addBlogModel.id}",
          updatedBlog.toJson(),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Update the preview image if a new one was selected
          // If user picked a new preview image on web:
          if (_previewImageBytes != null) {
            final imageResponse = await widget.networkHandler.patchImageWeb(
              "/blogpost/update/previewImage/${widget.addBlogModel.id}",
              _previewImageBytes!,
            );
            if (imageResponse.statusCode != 200 &&
                imageResponse.statusCode != 201) {
              throw Exception("Preview image upload (web) failed.");
            }
          }
          // If user picked a new preview image on mobile:
          else if (previewImageFile != null) {
            final imageResponse = await widget.networkHandler.patchImage(
              "/blogpost/update/previewImage/${widget.addBlogModel.id}",
              previewImageFile!.path,
            );
            if (imageResponse.statusCode != 200 &&
                imageResponse.statusCode != 201) {
              throw Exception("Preview image upload (mobile) failed.");
            }
          }
          // Otherwise, user didn't change preview image => do nothing

          // Upload new slideshow images if added
          for (Uint8List bytes in _newCoverImageBytes) {
            final imageResponse = await widget.networkHandler.patchImageWeb(
              "/blogpost/add/coverImages/${widget.addBlogModel.id}",
              bytes,
            );
            if (imageResponse.statusCode != 200 &&
                imageResponse.statusCode != 201) {
              throw Exception("Cover image upload (web) failed.");
            }
          }

          // 2) If user picked new cover images on mobile
          for (File file in newCoverImages) {
            final imageResponse = await widget.networkHandler.patchImage(
              "/blogpost/add/coverImages/${widget.addBlogModel.id}",
              file.path,
            );
            if (imageResponse.statusCode != 200 &&
                imageResponse.statusCode != 201) {
              throw Exception("Cover image upload (mobile) failed.");
            }
          }

          final notificationResponse = await networkHandler.post(
            "/notifications/notifyAdmins/updateShop/${widget.addBlogModel.email}/${widget.addBlogModel.id}",
            // Note: Ensure proper string interpolation
            {},
          );

          print(
              "Notification Response Code: ${notificationResponse.statusCode}");
          print("Notification Response Body: ${notificationResponse.body}");

          if (notificationResponse.statusCode == 200) {
            print("Admin notification sent successfully");
            PushNotifications.init();
          } else {
            print("Failed to notify admins");
          }

          await sendNotification(
            title: "Shop Modifications",
            body:
                "${widget.addBlogModel.email} has modified on his shop with the title: ${widget.addBlogModel.title}...",
          );
          // Dismiss the loading dialog before showing the success dialog
          Navigator.pop(context);
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: appColorNotifier.value, // Use main color
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.shopUpdated,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        color: appColorNotifier.value,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(AppLocalizations.of(context)!
                            .shopUpdatedSuccessfully),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the dialog
                        Navigator.pop(context); // Navigate back
                      },
                      child: Text(
                        AppLocalizations.of(context)!.ok,
                        style: TextStyle(color: appColorNotifier.value),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          throw Exception("Failed to update blog");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.errorUpdatingShop)));
        }
      }
    }
  }

  void _pickPreviewImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      if (kIsWeb) {
        // Web => read bytes
        final bytes = await pickedImage.readAsBytes();
        setState(() {
          _previewImageBytes = bytes;
          previewImageFile = null;
        });
      } else {
        // Mobile => store as File
        setState(() {
          previewImageFile = File(pickedImage.path);
          _previewImageBytes = null;
        });
      }
    }
  }

  void _pickNewCoverImages() async {
    final List<XFile>? pickedImages = await _picker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      if (kIsWeb) {
        // Web => read bytes for each
        for (var img in pickedImages) {
          final bytes = await img.readAsBytes();
          _newCoverImageBytes.add(bytes);
        }
        setState(() {}); // Refresh
      } else {
        // Mobile => store as File
        setState(() {
          newCoverImages=
              pickedImages.map((image) => File(image.path)).toList();
        });
      }
    }
  }

  void _removeExistingCoverImage(String imageUrl) async {
    try {
      final response = await widget.networkHandler.delete2(
        "/blogpost/remove/coverImage/${widget.addBlogModel.id}",
        body: jsonEncode(
            {"imageUrl": imageUrl}), // Pass the imageUrl in the request body
      );

      if (response['message'] == "Cover image removed successfully") {
        setState(() {
          existingCoverImages.remove(imageUrl); // Remove from the UI
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToRemoveImage)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Remove a newly selected cover image before uploading
  void _removeNewCoverImageAtIndex(int index, bool isWeb) {
    setState(() {
      if (isWeb) {
        _newCoverImageBytes.removeAt(index);
      } else {
        newCoverImages.removeAt(index);
      }
    });
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
        title: Text(
          AppLocalizations.of(context)!.editShop,
          style: const TextStyle(
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
                          items: [
                            DropdownMenuItem(
                                value: "general",
                                child: Text(
                                    AppLocalizations.of(context)!.general)),
                            DropdownMenuItem(
                                value: "barbershop",
                                child: Text(
                                    AppLocalizations.of(context)!.barbershop)),
                            DropdownMenuItem(
                                value: "hospital",
                                child: Text(
                                    AppLocalizations.of(context)!.hospital)),
                          ],
                          decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.type),
                        ),
                        const SizedBox(height: 24),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.title,
                            border: const OutlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.body,
                            border: const OutlineInputBorder(),
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
                          AppLocalizations.of(context)!.previewImage,
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
                            child: () {
                              // 1) If user picked a new preview image on web:
                              if (_previewImageBytes != null) {
                                return Image.memory(
                                  _previewImageBytes!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }
                              // 2) If user picked a new preview image on mobile:
                              if (previewImageFile != null) {
                                return Image.file(
                                  previewImageFile!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }
                              // 3) Otherwise, show existing from the server (if any)
                              if (widget.addBlogModel.previewImage != null) {
                                return Image.network(
                                  widget.networkHandler.formater2(
                                    widget.addBlogModel.previewImage!,
                                  ),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }
                              // 4) No preview image
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noPreviewImageSelected,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              );
                            }(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.center,
                          child: ValueListenableBuilder<Color>(
                            valueListenable: appColorNotifier,
                            builder: (context, color, child) {
                              return TextButton(
                                onPressed: _pickPreviewImage,
                                style: ButtonStyle(
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(color),
                                  padding: MaterialStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                  ),
                                ),
                                child:
                                Text(AppLocalizations.of(context)!.changePreviewImage),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // COVER IMAGES
                        Text(
                          AppLocalizations.of(context)!.slideshowImages,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        // Display existing cover images + newly selected
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 1) Existing from server
                            for (String imageUrl in existingCoverImages)
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          widget.networkHandler.formater2(imageUrl),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
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

                            // 2) Newly selected on WEB
                            for (int i = 0; i < _newCoverImageBytes.length; i++)
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: MemoryImage(_newCoverImageBytes[i]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        onPressed: () => _removeNewCoverImageAtIndex(
                                          i,
                                          true, // isWeb = true
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            // 3) Newly selected on MOBILE
                            for (int i = 0; i < newCoverImages.length; i++)
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: FileImage(newCoverImages[i]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        onPressed: () => _removeNewCoverImageAtIndex(
                                          i,
                                          false, // isWeb = false
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Button to pick new cover images
                        Align(
                          alignment: Alignment.center,
                          child: ValueListenableBuilder<Color>(
                            valueListenable: appColorNotifier,
                            builder: (context, color, child) {
                              return TextButton(
                                onPressed: _pickNewCoverImages,
                                style: ButtonStyle(
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(color),
                                  padding: MaterialStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!.addNewImages),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Changes
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _submitChanges,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.saveChanges),
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
