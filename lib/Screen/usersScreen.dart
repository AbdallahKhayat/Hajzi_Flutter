import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../NetworkHandler.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> users = []; // List to store fetched users
  NetworkHandler networkHandler = NetworkHandler();

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Fetch users on initialization
  }

  // Function to fetch users using NetworkHandler
  Future<void> fetchUsers() async {
    try {
      var response = await networkHandler.get("/user/getUsers");
      if (response != null && response['data'] != null) {
        setState(() {
          users = response['data']; // Refresh the users list from the server
        });
      } else {
        debugPrint("No users found: ${response['msg']}");
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  // Function to handle Ban/Unban button
  Future<void> toggleBanStatus(String email) async {
    try {
      var response = await networkHandler.patch("/user/ban/$email", {});
      var responseData = json.decode(response.body);

      if (response != null && responseData['Status'] == true) {
        setState(() {
          int userIndex = users.indexWhere((user) => user['email'] == email);
          if (userIndex != -1) {
            // Update the user's isBanned value locally from the server's response
            users[userIndex]['isBanned'] = responseData['isBanned'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  "User status updated successfully!")),
        );
      } else {
        debugPrint("Failed to ban/unban user: ${responseData['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData['message'] ?? "Failed to update user status.")),
        );
      }
    } catch (e) {
      debugPrint("Error banning/unbanning user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("An error occurred while updating the user status.")),
      );
    }
  }

  // Function to handle Promote/Unpromote button
  Future<void> toggleUserRole(String email, String currentRole) async {
    try {
      // Determine the new role based on the current role
      String newRole = currentRole == "customer" ? "user" : "customer";

      // Define the request body with the new role
      Map<String, dynamic> body = {"role": newRole};

      // Make the PATCH request
      var response =
          await networkHandler.patch("/user/updateRole/$email", body);

      // Decode the response body
      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData['msg'] ?? "User role updated successfully!")),
        );

        // Update the user's role locally in the list
        setState(() {
          int userIndex = users.indexWhere((user) => user['email'] == email);
          if (userIndex != -1) {
            users[userIndex]['role'] = newRole;
          }
        });
      } else {
        debugPrint("Failed to update user role: ${responseData['msg']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['msg'] ?? "Failed to update user role.")),
        );
      }
    } catch (e) {
      debugPrint("Error updating user role: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("An error occurred while updating the user role.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
      ),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Number of items per row
                      crossAxisSpacing: 10.0, // Spacing between columns
                      mainAxisSpacing: 10.0, // Spacing between rows
                      childAspectRatio: 2.0, // Adjust the aspect ratio of items
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index];
                      bool isBanned = user['isBanned'] == true;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Username: ${user['username']}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Email: ${user['email']}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Role: ${user['role']}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: user['role'] == "customer"
                                      ? Colors.blue
                                      : user['role'] == "admin"
                                          ? Colors.red
                                          : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBanned ? "Status: Banned" : "Status: Active",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isBanned ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        toggleBanStatus(user['email']),
                                    child: Text(
                                      isBanned ? "Unban" : "Ban",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isBanned
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    // style: TextButton.styleFrom(
                                    //   foregroundColor:
                                    //       isBanned ? Colors.green : Colors.red,
                                    // ),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () => toggleUserRole(
                                        user['email'], user['role']),
                                    child: Text(user['role'] == "customer"
                                        ? "Unpromote"
                                        : "Promote",style:
                                      TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),),
                                    // style: TextButton.styleFrom(
                                    //   foregroundColor: Colors.green,
                                    // ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    bool isBanned = user['isBanned'] == true;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Username: ${user['username']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Email: ${user['email']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Role: ${user['role']}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: user['role'] == "customer"
                                    ? Colors.blue
                                    : user['role'] == "admin"
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBanned ? "Status: Banned" : "Status: Active",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isBanned ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      toggleBanStatus(user['email']),
                                  child: Text(isBanned ? "Unban" : "Ban"),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        isBanned ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: () => toggleUserRole(
                                      user['email'], user['role']),
                                  child: Text(user['role'] == "customer"
                                      ? "Unpromote"
                                      : "Promote"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
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
