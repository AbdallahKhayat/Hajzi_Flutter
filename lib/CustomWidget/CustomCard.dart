import 'package:blogapp/Pages/IndividualPage.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // For time formatting
import 'package:blogapp/NetworkHandler.dart'; // Assuming you have this for API calls

class CustomCard extends StatefulWidget {
  final Map<String, dynamic> chat;
  final NetworkHandler networkHandler = NetworkHandler(); // Initialize NetworkHandler

  CustomCard({super.key, required this.chat});

  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchProfileImage();
  }

  Future<void> fetchProfileImage() async {
    try {
      // Assuming you have an endpoint to get profile data by email
      String? token = await storage.read(key: "token");
      if (token == null) {
        print('No token found');
        return;
      }

      String chatPartnerEmail = widget.chat['chatPartnerEmail'];
      final response = await widget.networkHandler.get('/profile/getDataByEmail?email=$chatPartnerEmail');

      if (response != null && response.containsKey('data')) {
        String? imgPath = response['data']['img'];
        if (imgPath != null && imgPath.isNotEmpty) {
          // Construct the full URL to the image
          // Replace 'your-backend-url' with your actual backend URL
          setState(() {
            profileImageUrl = 'https://hajzi-6883b1f029cf.herokuapp.com/' + imgPath;
          });
        }
      } else {
        print('Error fetching profile data');
      }
    } catch (e) {
      print('Error in fetchProfileImage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: storage.read(key: "email"),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final String? currentUserEmail = snapshot.data;
        final chatPartner = widget.chat['users'].firstWhere(
                (user) => user['email'] != currentUserEmail,
            orElse: () => {'email': 'Unknown', 'username': 'Unknown'}
        );

        final chatPartnerName = chatPartner['username'] ?? 'Unknown User';
        final chatPartnerEmail = chatPartner['email'] ?? 'Unknown';
        final lastMessage = widget.chat['lastMessage'] ?? 'No messages yet';
        final lastMessageTime = widget.chat['lastMessageTime'] ?? '';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualPage(
                  initialChatId: widget.chat['_id'],
                  chatPartnerEmail: chatPartnerEmail,
                  chatPartnerName: chatPartnerName,
                ),
              ),
            );
          },
          child: Column(
            children: [
              ListTile(
                leading: profileImageUrl != null
                    ? CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(profileImageUrl!),
                )
                    : ValueListenableBuilder<Color>(
                  valueListenable: appColorNotifier,
                  builder: (context, currentColor, child) {
                    return CircleAvatar(
                      radius: 30,
                      backgroundColor: currentColor,
                      child: Text(
                        chatPartnerName.isNotEmpty
                            ? chatPartnerName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    );
                  },
                ),
                title: Text(
                  chatPartnerName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    // Always show double blue ticks
                    const Icon(Icons.done_all, color: Colors.blue, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  formatLocalTime(lastMessageTime),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 20, left: 80),
                child: Divider(thickness: 1),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatLocalTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '';
    try {
      final DateTime dateTime = DateTime.parse(isoTime).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }
}
