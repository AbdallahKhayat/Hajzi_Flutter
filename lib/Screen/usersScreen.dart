import 'package:blogapp/constants.dart';
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
  TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchUsers(); // Fetch users on initialization
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      fetchUsers(); // Reset to full list if search is empty
      return;
    }


      var response = await networkHandler.get("/user/search/$query");

    if (response != null) {
      if (response is List) {
        // If response is already a list, assign it directly
        setState(() {
          users = response;
        });
      } else if (response['data'] != null && response['data'] is List) {
        // If response contains 'data' key and it's a list, assign the data
        setState(() {
          users = response['data'];
        });
      }
    } else {
      debugPrint("No users found");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No users found")),
      );
    }


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
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (query) => searchUsers(query),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Search Users...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
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
        elevation: 0, // Optional: Remove shadow from AppBar
      ),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // Number of items per row
            crossAxisSpacing: 10.0, // Spacing between columns
            mainAxisSpacing: 10.0, // Spacing between rows
            childAspectRatio: 2, // Adjust the aspect ratio of items
          ),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index]),
        ),
      )
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => _buildUserCard(users[index]),
      ),
    );
  }

  Widget _buildUserCard(user) {
    bool isBanned = user['isBanned'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300, width: 1),
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
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Role: ${user['role']}",
              style: TextStyle(
                fontSize: 16,
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isBanned ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => toggleBanStatus(user['email']),
                  child: Text(
                    isBanned ? "Unban" : "Ban",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isBanned ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => toggleUserRole(user['email'], user['role']),
                  child: Text(
                    user['role'] == "customer" ? "Unpromote" : "Promote",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
