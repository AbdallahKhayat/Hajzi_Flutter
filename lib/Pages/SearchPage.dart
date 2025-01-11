import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import '../constants.dart';
import 'IndividualPage.dart'; // 🔥 Import your network handler
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> customers = []; // 🔥 List of all customers
  List<dynamic> filteredCustomers = []; // 🔥 Filtered list of customers
  TextEditingController searchController =
      TextEditingController(); // 🔥 For search bar input

  @override
  void initState() {
    super.initState();
    fetchCustomers(); // Fetch customers when the page loads
  }

  /// 🔥 Fetch customers from the server
  Future<void> fetchCustomers() async {
    try {
      var response = await NetworkHandler().get('/user/customers');
      if (response != null && response is List) {
        setState(() {
          customers = response;
          filteredCustomers = customers;
        });
      } else {
        setState(() {
          customers = [];
        });
        print('Error fetching customers');
      }
    } catch (e) {
      setState(() {
        customers = [];
      });
      print('Error: $e');
    }
  }

  /// 🔥 Filter the customer list based on search input
  void filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers; // Reset to full list
      } else {
        filteredCustomers = customers.where((customer) {
          final customerName = customer['username'].toLowerCase();
          final searchQuery = query.toLowerCase();
          return customerName.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<String?> fetchExistingChatId(String partnerEmail) async {
    try {
      final response = await NetworkHandler()
          .get('/chat/existing?partnerEmail=$partnerEmail');
      // Ensure `NetworkHandler().get()` returns the decoded JSON. If it returns a raw response, decode it here.
      if (response != null && response is Map) {
        // If the response contains '_id', it means chat exists
        if (response['_id'] != null) {
          return response['_id'];
        }
      }
      return null; // No existing chat found
    } catch (e) {
      print("Error checking for existing chat: $e");
      return null;
    }
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
          controller: searchController,
          onChanged: (value) => filterCustomers(value),
          // 🔥 Call filter as user types
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchForCustomers,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
        ),
      ),
      body: customers.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noShopsFound,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            )
          : filteredCustomers.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noMatchingShops,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ) // Loading state
              : ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return UserCard(
                      email: customer['email'],
                      username: customer['username'],
                      imgPath: customer['profile']?['img'] ?? '',
                      onTap: () async {
                        final existingChatId =
                            await fetchExistingChatId(customer['email']);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualPage(
                              initialChatId: existingChatId ?? '',
                              chatPartnerEmail: customer['email'],
                              chatPartnerName: customer['username'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

/// Custom Widget to Display User Information with Profile Image
class UserCard extends StatelessWidget {
  final String email;
  final String username;
  final String imgPath;
  final VoidCallback onTap;

  const UserCard({
    Key? key,
    required this.email,
    required this.username,
    required this.imgPath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String? profileImageUrl =
        imgPath.isNotEmpty ? imgPath + '?v=$timestamp' : null;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          ListTile(
            leading: profileImageUrl != null
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        CachedNetworkImageProvider(profileImageUrl),
                    backgroundColor: Colors.transparent,
                    onBackgroundImageError: (_, __) {
                      // Handle image load error if necessary
                    },
                  )
                : ValueListenableBuilder<Color>(
                    valueListenable: appColorNotifier,
                    builder: (context, currentColor, child) {
                      return CircleAvatar(
                        radius: 30,
                        backgroundColor: currentColor,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
            title: Text(
              username,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              email,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }
}
