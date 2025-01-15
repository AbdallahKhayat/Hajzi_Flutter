import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/Models/addBlogApproval.dart';
import 'package:blogapp/Models/addBlogModel.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<AddBlogApproval> blogRequests = [];
  List<AddBlogApproval> filteredRequests = [];
  NetworkHandler networkHandler = NetworkHandler();
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  AddBlogModel addBlogModel = AddBlogModel();

  @override
  void initState() {
    super.initState();
    fetchPendingBlogs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingBlogs() async {
    setState(() {
      isLoading = true;
    });

    var response = await networkHandler.get("/AddBlogApproval/requests");

    if (response is Map && response.containsKey("data")) {
      List<dynamic> data = response["data"];
      setState(() {
        blogRequests =
            data.map((json) => AddBlogApproval.fromJson(json)).toList();
        filteredRequests = blogRequests; // Initially show all requests
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToFetchBlogRequests), // CHANGED
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      // Reset to show all requests when the search query is cleared
      setState(() {
        filteredRequests = blogRequests;
      });
    } else {
      // Filter requests based on the title
      setState(() {
        filteredRequests = blogRequests
            .where((blog) => (blog.title ?? '').toLowerCase().contains(query))
            .toList();
      });
    }
  }

  Future<void> updateBlogStatus(String blogId, String status) async {
    setState(() {
      isLoading = true;
    });

    var response = await networkHandler.patch(
      "/AddBlogApproval/updateStatus/$blogId",
      {
        "status": status,
      },
    );

    if (response.statusCode == 200) {
      // Send notification after status update
      final blog = blogRequests.firstWhere((request) => request.id == blogId);
      final customerEmail =
          blog.email; // Assuming username is the customer's email

      // Send notification to the customer
      await sendNotification(
        email: customerEmail!,
        title:   AppLocalizations.of(context)!.shopStatusUpdated, // CHANGED
        body:
        "Your Shop with title: ${blog.title} has been $status by the admin.",
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.shopStatusUpdated, // CHANGED
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == "approved" ? Colors.green : Colors.red,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.shopStatusUpdatedMessage(blog.title ?? "N/A", status),
              style: TextStyle(color: Colors.black),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(
                  AppLocalizations.of(context)!.ok, // CHANGED
                  style: TextStyle(
                    color: status == "approved" ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );

      setState(() {
        blogRequests.removeWhere((request) => request.id == blogId);
        filteredRequests.removeWhere((request) => request.id == blogId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToUpdateShopStatus),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> sendNotification({
    required String email,
    required String title,
    required String body,
  }) async {
    try {
      final response = await networkHandler.post("/notifications/send", {
        "title": title,
        "body": body,
        "recipient": email, // Send to customer's email
      });
      final responseBody = json.decode(response.body);

      print("Notification Sent: ${responseBody['message']}");
    } catch (error) {
      print("Error sending notification: $error");
    }
  }

  Future<List<String>> _fetchImages(String blogId) async {
    try {
      var response = await networkHandler.get("/AddBlogApproval/$blogId");

      if (response is Map<String, dynamic> && response.containsKey("data")) {
        final blogData = response["data"];

        // Extract previewImage and coverImages
        final previewImage = blogData["previewImage"] as String?;
        final coverImages =
            (blogData["coverImages"] as List?)?.cast<String>() ?? [];

        // Log the images for debugging
        print("Preview Image: $previewImage");
        print("Cover Images: $coverImages");

        // Combine previewImage and coverImages into a single list with the full URL
        final urls = [
          if (previewImage != null) networkHandler.formater(previewImage),
          ...coverImages.map((image) => networkHandler.formater(image)),
        ];

        // Check if the images are accessible
        for (var url in urls) {
          print("Checking URL: $url");
          final isAccessible = await _isImageAccessible(url);
          if (!isAccessible) {
            print("⚠️ Image URL is not accessible: $url");
          }
        }

        return urls;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }

  Future<bool> _isImageAccessible(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200 && response.headers['content-length'] != '0';
    } catch (e) {
      print("Error checking image accessibility: $e");
      return false;
    }
  }


  Future<void> _showDetails(AddBlogApproval blog) async {
    // Fetch all images associated with this blog request
    List<String> images = await _fetchImages(blog.id!);

    // Determine the preview image (assuming the first image is the preview)
    String? previewImage = images.isNotEmpty ? images[0] : null;

    // The rest of the images are considered cover images
    List<String> coverImages = images.length > 1 ? images.sublist(1) : [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.shopDetails), // CHANGED
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.usernameLabel, // CHANGED
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(blog.username ?? "N/A"),
                  ],
                ),
                const SizedBox(height: 10),
                // Email
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.emailLabel, // CHANGED
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                Text(
                  blog.email ?? "N/A",
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height:20),
                // Preview Image
                Text(
                  AppLocalizations.of(context)!.previewImage, // CHANGED
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                previewImage != null
                    ? Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(previewImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    : Text(
                  AppLocalizations.of(context)!.noPreviewImageUploaded, // CHANGED
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // Cover Images
                Text(
                  AppLocalizations.of(context)!.coverImages, // CHANGED
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                coverImages.isNotEmpty
                    ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: coverImages
                      .map(
                        (url) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                )
                    : Text(
                  AppLocalizations.of(context)!.noCoverImagesUploaded, // CHANGED
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchByTitle, // CHANGED
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRequests.isEmpty
          ? Center(
        child: Text(
          AppLocalizations.of(context)!.noShopRequestsFound, // CHANGED
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final blog = filteredRequests[index];
          return kIsWeb
              ? Center(
            child: SizedBox(
              width: 650,
              // height: 200,
              child: Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        blog.title ?? AppLocalizations.of(context)!.untitledBlog, // CHANGED
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        blog.body ?? AppLocalizations.of(context)!.noContentAvailable, // CHANGED
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => updateBlogStatus(
                                blog.id!, "approved"),
                            icon: const Icon(
                              Icons.check,
                              color: Colors.black,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.approve, // CHANGED
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => updateBlogStatus(
                                blog.id!, "rejected"),
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.black,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.deny, // CHANGED
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12),
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                            ),
                          ),

                          // View Details Button
                          ElevatedButton.icon(
                            onPressed: () => _showDetails(blog),
                            icon: const Icon(Icons.info,
                                color: Colors.black),
                            label: Text(
                              AppLocalizations.of(context)!.viewDetails, // CHANGED
                              style: const TextStyle(
                                  color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              : Stack(children: [
            Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.title ?? AppLocalizations.of(context)!.untitledBlog, // CHANGED
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blog.body ?? AppLocalizations.of(context)!.noContentAvailable, // CHANGED
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => updateBlogStatus(
                              blog.id!, "approved"),
                          icon: const Icon(
                            Icons.check,
                            color: Colors.black,
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.approve, // CHANGED
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => updateBlogStatus(
                              blog.id!, "rejected"),
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.black,
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.deny, // CHANGED
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        // View Details Button
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 15,
              right: 35,
              child: ElevatedButton.icon(
                onPressed: () => _showDetails(blog),
                icon: const Icon(Icons.info_outline,
                    color: Colors.white, size: 18),
                label: Text(
                  AppLocalizations.of(context)!.details, // CHANGED
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
