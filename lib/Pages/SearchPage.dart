import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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

  // 🔥 ADDED: Fetch the shops owned by a given user (by email).
  Future<List<dynamic>> fetchUserShops(String email) async {
    try {
      // Make sure this path matches your new endpoint from the Node server
      final response =
          await NetworkHandler().get('/blogpost/getShopsByEmail/$email');
      if (response != null && response is Map && response['data'] != null) {
        return response['data']; // This should be the List of shops
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching user shops: $e");
      return [];
    }
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
                      // 🔥 ADDED: Provide a callback to show shops when info icon is tapped
                      onInfoTap: () async {
                        final userShops =
                            await fetchUserShops(customer['email']);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              // Adjust the insetPadding to decrease the dialog width on web.
                              insetPadding: kIsWeb
                                  ? const EdgeInsets.symmetric(horizontal: 490)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 40.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              title: Row(
                                children: [
                                  const Icon(Icons.store, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${customer['username']} ${AppLocalizations.of(context)!.shops}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: userShops.isEmpty
                                  ? Text(AppLocalizations.of(context)!
                                      .noShopsFoundSearch)
                                  : SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: userShops.length,
                                        itemBuilder: (context, idx) {
                                          final shop = userShops[idx];
                                          return ShopPreviewItem(shop: shop);
                                        },
                                      ),
                                    ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.close,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            );
                          },
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

// 🔥 ADDED: A separate callback for the info icon
  final VoidCallback onInfoTap;

  const UserCard({
    Key? key,
    required this.email,
    required this.username,
    required this.imgPath,
    required this.onTap,
    required this.onInfoTap,
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
            // 🔥 ADDED: trailing icon button
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: onInfoTap,
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

/// Displays the preview image (if any) and the shop title.
class ShopPreviewItem extends StatelessWidget {
  final Map<String, dynamic> shop;

  const ShopPreviewItem({Key? key, required this.shop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? previewUrl = shop['previewImage'];
    final String title = shop['title'] ?? 'Untitled Shop';

    // Define a target width for web.
    final double targetWidth = kIsWeb ? 500.0 : double.infinity;

    return Center(
      // The Center widget constrains the Card to its intrinsic size.
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: targetWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Show shop preview image or a gray placeholder
              if (previewUrl != null && previewUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: previewUrl,
                    width: targetWidth,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: targetWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              // The Shop title
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
