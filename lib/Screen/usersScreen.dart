import 'package:blogapp/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../NetworkHandler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

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

  Future<void> _showBanConfirmationDialog(String email, bool isBanned) async {
    String action = isBanned ? AppLocalizations.of(context)!.unban : AppLocalizations.of(context)!.ban;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isBanned
                ? AppLocalizations.of(context)!.confirmUnban
                : AppLocalizations.of(context)!.confirmBan,
          ),
          content: Text(
            isBanned
                ? AppLocalizations.of(context)!.areYouSureUnban(email)
                : AppLocalizations.of(context)!.areYouSureBan(email),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                toggleBanStatusConfirmed(email); // Proceed with ban/unban
              },
              child: Text(
                action.capitalize(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showUserProfileDialog({
    required BuildContext context,
    required NetworkHandler networkHandler,
    required String email,
  }) async {
    try {
      // 1) Fetch user data by email
      final response =
      await networkHandler.get("/profile/getDataByEmail?email=$email");

      if (response == null || response['data'] == null) {
        throw Exception("No data found for this user.");
      }

      // 2) Parse the user data
      final userData = response['data']; // This is a Map<String, dynamic>
      // Alternatively, if you want to parse into a ProfileModel:
      // final profile = ProfileModel.fromJson(response['data']);

      // 3) Show the dialog with user information
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${AppLocalizations.of(context)!.userProfile}: ${userData['name'] ?? AppLocalizations.of(context)!.unknown}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display image if available
                  Center(
                    child: userData['img'] != null && userData['img'].toString().isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        userData['img'],
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    )
                        : Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: AppLocalizations.of(context)!.emailLabel,
                    value: userData['email'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.work,
                    label: AppLocalizations.of(context)!.professionLabel,
                    value: userData['profession'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: AppLocalizations.of(context)!.dobLabel,
                    value: userData['DOB'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.title,
                    label: AppLocalizations.of(context)!.titlelineLabel,
                    value: userData['titleline'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.info,
                    label: AppLocalizations.of(context)!.aboutLabel,
                    value: userData['about'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      debugPrint("Error fetching user profile: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching user profile.")),
      );
    }
  }


  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> toggleBanStatusConfirmed(String email) async {
    try {
      var response = await networkHandler.patch("/user/ban/$email", {});
      var responseData = json.decode(response.body);

      if (response != null && responseData['Status'] == true) {
        setState(() {
          int userIndex = users.indexWhere((user) => user['email'] == email);
          if (userIndex != -1) {
            users[userIndex]['isBanned'] = responseData['isBanned'];
          }
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.block,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8), // Spacing between icon and text
                  Text(
                    AppLocalizations.of(context)!.userStatusUpdate,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: Colors.red,
                    size: 36,
                  ),
                  SizedBox(width: 10), // Spacing between icon and message
                  Expanded(
                      child: Text(AppLocalizations.of(context)!.userStatusUpdatedSuccessfully(email)),

                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    AppLocalizations.of(context)!.ok,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        debugPrint("Failed to ban/unban user: ${responseData['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData['message'] ?? AppLocalizations.of(context)!.failedToUpdateStatus
              )),
        );
      }
    } catch (e) {
      debugPrint("Error banning/unbanning user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingStatus)
        ),
      );
    }
  }

  Future<void> _showRoleConfirmationDialog(
      String email, String currentRole) async {
    String action = currentRole == "customer"
        ? AppLocalizations.of(context)!.unpromote
        : AppLocalizations.of(context)!.promote;
    String newRole = currentRole == "customer"
        ? AppLocalizations.of(context)!.user
        : AppLocalizations.of(context)!.customer;


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action),
          content: Text(AppLocalizations.of(context)!.areYouSureChangeRole(email, newRole)),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                toggleUserRoleConfirmed(
                    email, currentRole); // Proceed with role change
              },
              child: Text(
                action.capitalize(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> toggleUserRoleConfirmed(String email, String currentRole) async {
    try {
      String newRole = currentRole == "customer" ? "user" : "customer";
      Map<String, dynamic> body = {"role": newRole};

      var response =
      await networkHandler.patch("/user/updateRole/$email", body);
      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8), // Spacing between icon and text
                  Text(
                    AppLocalizations.of(context)!.roleUpdate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Colors.blue,
                    size: 36,
                  ),
                  SizedBox(width: 10), // Spacing between icon and message
                  Expanded(

                      child: Text(AppLocalizations.of(context)!.roleUpdatedSuccessfully(email)),

                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    AppLocalizations.of(context)!.ok,
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        );

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
              Text(responseData['msg'] ?? AppLocalizations.of(context)!.failedToUpdateRole)),
        );
      }
    } catch (e) {
      debugPrint("Error updating user role: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("An error occurred while updating the user role.")),
      );
    }
  }

  //////

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
              content: Text(responseData['message'] ?? AppLocalizations.of(context)!.userStatusUpdated
              )),
        );
      } else {
        debugPrint("Failed to ban/unban user: ${responseData['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData['message'] ?? AppLocalizations.of(context)!.failedToUpdateStatus
              )),
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
                content: Text(responseData['msg'] ?? AppLocalizations.of(context)!.failedToUpdateRole))
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
              hintText: AppLocalizations.of(context)!.searchUsers,
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
      // Wrap the body in a Scrollbar:
      body: Scrollbar(
        thumbVisibility: true, // always show the scrollbar thumb on web
        child: kIsWeb
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            // Let GridView handle its own scrolling
            itemCount: users.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 5 / 4,
            ),
            itemBuilder: (context, index) =>
                _buildUserCard(users[index]),
          ),
        )
            : ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index]),
        ),
      ),
    );
  }

  Widget _buildUserCard(user) {
    bool isBanned = user['isBanned'] == true;
    final userEmail = user['email'] ?? '';
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
              "${AppLocalizations.of(context)!.usernameLabel} ${user['username']}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: userEmail.contains('@')
                  ? () {
                showUserProfileDialog(
                  context: context,
                  networkHandler: networkHandler,
                  email: userEmail,
                );
              }
                  : null,
              child: Text(
                "${AppLocalizations.of(context)!.emailLabel}: $userEmail",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${AppLocalizations.of(context)!.roleLabel}: ${user['role']}",
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
              "${AppLocalizations.of(context)!.statusLabel}: " +
                  (isBanned ? AppLocalizations.of(context)!.banned : AppLocalizations.of(context)!.active),
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
                  onPressed: () => _showBanConfirmationDialog(
                      user['email'], user['isBanned']),
                  child: Text(
                    isBanned ? AppLocalizations.of(context)!.unban : AppLocalizations.of(context)!.ban,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isBanned ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () =>
                      _showRoleConfirmationDialog(user['email'], user['role']),
                  child: Text(
                    user['role'] == "customer" ? AppLocalizations.of(context)!.unpromote : AppLocalizations.of(context)!.promote,
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