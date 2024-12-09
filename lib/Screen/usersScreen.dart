import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
      var response = await networkHandler.get("/user/getUsers"); // Use your get method
      if (response != null && response['data'] != null) {
        setState(() {
          users = response['data'];
        });
      } else {
        debugPrint("No users found: ${response['msg']}");
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  // Function to handle Ban button
  Future<void> banUser(String email) async {
    try {
      var response = await networkHandler.get("/user/ban/$email"); // Assuming a ban endpoint
      if (response['Status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User banned successfully!")),
        );
        fetchUsers(); // Refresh user list
      } else {
        debugPrint("Failed to ban user: ${response['msg']}");
      }
    } catch (e) {
      debugPrint("Error banning user: $e");
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
      var response = await networkHandler.patch("/user/updateRole/$email", body);

      // Decode the response body
      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['msg'] ?? "User role updated successfully!")),
        );
        fetchUsers(); // Refresh user list
      } else {
        debugPrint("Failed to update user role: ${responseData['msg']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['msg'] ?? "Failed to update user role.")),
        );
      }
    } catch (e) {
      debugPrint("Error updating user role: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while updating the user role.")),
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
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white, // Card background color
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
              border: Border.all(color: Colors.grey.shade300, width: 1), // Border color and width
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 4), // Shadow position
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => banUser(user['email']),
                        child: const Text("Ban"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => toggleUserRole(user['email'], user['role']),
                        child: Text(
                          user['role'] == "customer" ? "Unpromote" : "Promote",
                        ),
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
