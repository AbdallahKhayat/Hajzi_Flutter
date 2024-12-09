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
 NetworkHandler networkHandler= NetworkHandler();
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

  // Function to handle Promote button
  Future<void> promoteUser(String email) async {
    try {
      var response = await networkHandler.get("/user/updateRole/$email"); // Assuming promote endpoint
      if (response['Status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User promoted successfully!")),
        );
        fetchUsers(); // Refresh user list
      } else {
        debugPrint("Failed to promote user: ${response['msg']}");
      }
    } catch (e) {
      debugPrint("Error promoting user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
      ),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Username: ${user['username']}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("Email: ${user['email']}"),
                  Text("Role: ${user['role']}"),
                  const SizedBox(height: 10),
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
                        onPressed: () => promoteUser(user['email']),
                        child: const Text("Promote"),
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
