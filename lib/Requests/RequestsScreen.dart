import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/Models/addBlogApproval.dart';
import 'package:blogapp/NetworkHandler.dart';

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
        const SnackBar(
          content: Text("Failed to fetch blog requests"),
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
      final customerEmail = blog.email; // Assuming username is the customer's email

      // Send notification to the customer
      await sendNotification(
        email: customerEmail!,
        title: "Blog Status Updated",
        body: "Your blog with title: ${blog.title} has been $status by the admin.",
      );


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Blog status updated to $status"),
          backgroundColor: status == "approved" ? Colors.green : Colors.red,
        ),
      );
      setState(() {
        blogRequests.removeWhere((request) => request.id == blogId);
        filteredRequests.removeWhere((request) => request.id == blogId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update blog status"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Search by title...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRequests.isEmpty
              ? const Center(
                  child: Text(
                    "No Shop requests found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        blog.title ?? "Untitled Blog",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        blog.body ?? "No content available",
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
                                            label: const Text(
                                              "Approve",
                                              style: TextStyle(
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
                                            label: const Text(
                                              "Deny",
                                              style: TextStyle(
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
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ),
                        )
                        : Card(
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
                                    blog.title ?? "Untitled Blog",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    blog.body ?? "No content available",
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
                                        label: const Text(
                                          "Approve",
                                          style: TextStyle(
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
                                        label: const Text(
                                          "Deny",
                                          style: TextStyle(
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                  },
                ),
    );
  }
}

// Future<void> updateBlogStatus(String blogId, String status) async {
//   setState(() {
//     isLoading = true;
//   });
//
//   try {
//     // Fetch the blog approval details first to get the original username
//     final approvalResponse = await networkHandler.get("/AddBlogApproval/$blogId");
//
//     // Check if the response contains valid data (original username)
//     if (approvalResponse != null && approvalResponse.containsKey("data") && approvalResponse["data"].containsKey("username")) {
//       var blogData = approvalResponse["data"];
//       String customerUsername = blogData["username"]; // Original customer's username
//
//       // If the status is "approved", we can add it to the main blog post schema
//       if (status == "approved") {
//         AddBlogModel newBlog = AddBlogModel(
//           title: blogData["title"],
//           body: blogData["body"],
//           username: customerUsername,  // Use the original customer's username
//           status: "approved",
//           createdAt: DateTime.now(),
//         );
//
//         // Now send the approval update with the blog data
//         final addResponse = await networkHandler.post("/blogpost/Add", newBlog.toJson());
//
//         if (addResponse.statusCode == 200 || addResponse.statusCode == 201) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Blog approved and added successfully!"),
//               backgroundColor: Colors.green,
//             ),
//           );
//
//           // Remove the approved blog from the pending list
//           setState(() {
//             blogRequests.removeWhere((request) => request.id == blogId); // Remove from the list
//           });
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Failed to add blog to the blogpost schema"),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Blog was rejected"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Failed to retrieve customer details or blog data"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("An error occurred: $e"),
//         backgroundColor: Colors.red,
//       ),
//     );
//     print("Error: $e");
//   }
//
//   setState(() {
//     isLoading = false;
//   });
// }

// Future<void> updateBlogStatus(String blogId, String status) async {
//   setState(() {
//     isLoading = true;
//   });
//   var response = await networkHandler.patch(
//     "/AddBlogApproval/updateStatus/$blogId",  // Updated endpoint for status update
//     {"status": status},
//   );
//
//   if (response.statusCode == 200) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Blog status updated to $status"),
//         backgroundColor: status == "approved" ? Colors.green : Colors.red,
//       ),
//     );
//     setState(() {
//       blogRequests.removeWhere((request) => request.id == blogId); // Remove the blog from the list
//     });
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Failed to update blog status"),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//   setState(() {
//     isLoading = false;
//   });
// }
