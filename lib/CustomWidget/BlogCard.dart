import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Blog/BlogAfterClick.dart';
import '../Models/addBlogModel.dart';
import '../NetworkHandler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../Screen/editshopscreen.dart';

class BlogCard extends StatefulWidget {
  BlogCard(
      {super.key,
      required this.addBlogModel,
      required this.networkHandler,
      required this.onDelete,
      required this.flag});

  final AddBlogModel addBlogModel;
  final NetworkHandler networkHandler;
  final VoidCallback onDelete;
  final int flag;

  @override
  State<BlogCard> createState() => _BlogCardState();
}

class _BlogCardState extends State<BlogCard> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  String? userRole;

  // Load the user role from secure storage
  Future<void> _loadUserRole() async {
    final role = await storage.read(key: "role");
    setState(() {
      userRole = role;
    });
  }

  NetworkHandler networkHandler = NetworkHandler();

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Load the role when the widget is initialized
  }

  Future<void> sendNotification({
    required String email,
    required String title,
    required String body,
  }) async {
    try {
      print("Sending notification to: $email");
      final response = await widget.networkHandler.post("/notifications/send", {
        "title": title,
        "body": body,
        "recipient": email,
      });

      final responseBody = json.decode(response.body);
      if (response != null && responseBody['Status'] == true) {
        print("Notification sent successfully: ${responseBody['message']}");
      } else {
        print("Failed to send notification: ${responseBody['message']}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debugging: Print the previewImage URL
    print("Preview Image URL: ${widget.addBlogModel.previewImage}");
    return GestureDetector(
      onTap: () {
        // Navigate to the BlogAfterClick page to show all slide images
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogAfterClick(
              addBlogModel: widget.addBlogModel,
              networkHandler: widget.networkHandler,
            ),
          ),
        );
      },
      child: kIsWeb //web part//////////////////////////
          ? Container(
              padding: const EdgeInsets.all(8.0),
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.circular(12.0),
              //   border: Border.all(color: Colors.grey.shade300, width: 1),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.grey.shade200,
              //       blurRadius: 8.0,
              //       spreadRadius: 2.0,
              //       offset: const Offset(0, 4),
              //     ),
              //   ],
              // ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Blog Preview Image with Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: widget.networkHandler.getImageBlog(
                              widget.addBlogModel.previewImage ?? ""),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.1),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),

                    // Admin Controls (Delete button)
                    if (userRole == "admin")
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title:  Text(AppLocalizations.of(context)!.confirmDeletion),
                                  content: Text(
                                    "${AppLocalizations.of(context)!.deleteShopConfirmationWithTitle} ${widget.addBlogModel.title}?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(false), // Cancel
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(true), // Confirm
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              // Proceed with deletion
                              try {
                                final response =
                                    await widget.networkHandler.delete(
                                  "/blogpost/delete/${widget.addBlogModel.id}",
                                );

                                print("Delete Response: $response");

                                if (response['Status'] == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!.noPermissionToDeleteBlog,
                                      ),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8), // Spacing between icon and text
                                            Text(
                                              AppLocalizations.of(context)!.deletionSuccessful,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        content:  Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.green,
                                              size: 36,
                                            ),
                                            SizedBox(width: 10), // Spacing between icon and message
                                            Expanded(
                                              child: Text(
                                                "${AppLocalizations.of(context)!.shopDeletedSuccessfully} ${widget.addBlogModel.title} ${AppLocalizations.of(context)!.successfullyDeleted}",
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child: Text(
                                            AppLocalizations.of(context)!.ok  ,
                                              style: const TextStyle(color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );


                                  widget.onDelete();
                                }
                              } catch (e) {
                                print("Delete Error: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${AppLocalizations.of(context)!.somethingWentWrong}: $e",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete,
                            size: 30, // Resized to fit within the card
                          ),
                          color: Colors.redAccent,
                        ),
                      ),

                    // Blog Title Container
                    Positioned(
                      bottom: 16, // Spacing from the bottom edge
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.addBlogModel.title ?? AppLocalizations.of(context)!.untitledBlog,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Edit Icon at the top-left
                    if (widget.flag == 1)
                      if (userRole == "customer")
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditShopScreen(
                                    addBlogModel: widget.addBlogModel,
                                    networkHandler: widget.networkHandler,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.teal,
                              size: 30, // Resized to fit within the card
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            )
          : Container(
              height: 320,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.hardEdge,
                // Ensures content is clipped to the rounded edges
                child: Stack(
                  children: [
                    // Blog Preview Image with Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: widget.networkHandler.getImageBlog(
                              widget.addBlogModel.previewImage ?? ""),
                          // Use previewImage
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.1),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // Admin Controls (Delete button)
                    if (userRole == "admin")
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.confirmDeletion),
                                  content: Text(
                                    "${AppLocalizations.of(context)!.deleteShopConfirmationWithTitle} ${widget.addBlogModel.title}?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(false), // Cancel
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(true), // Confirm
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              // Proceed with deletion
                              try {
                                final response =
                                    await widget.networkHandler.delete(
                                  "/blogpost/delete/${widget.addBlogModel.id}",
                                );

                                print("Delete Response: $response");

                                if (response['Status'] == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!.noPermissionToDeleteBlog,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                      Text(AppLocalizations.of(context)!.deletionSuccessful),
                                    ),
                                  );

                                  widget.onDelete();
                                }
                              } catch (e) {
                                print("Delete Error: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${AppLocalizations.of(context)!.somethingWentWrong}: $e",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete,
                            size: 30, // Resized to fit within the card
                          ),
                          color: Colors.redAccent,
                        ),
                      ),

                    // Title Container at the bottom
                    Positioned(
                      bottom: 16, // Spacing from the bottom edge
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.addBlogModel.title ?? AppLocalizations.of(context)!.untitledBlog,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (widget.flag == 1)
                      if (userRole == "customer")
                        Positioned(
                          top: 5, // Spacing from the top edge
                          right: 3,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditShopScreen(
                                    addBlogModel: widget.addBlogModel,
                                    networkHandler: widget.networkHandler,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.edit,
                              color: Colors.teal.shade200,
                              size: 40,
                            ),
                          ),
                        )

                    // Optional Add: Blog Details Button (can be removed)
                  ],
                ),
              ),
            ),
    );
  }
}

