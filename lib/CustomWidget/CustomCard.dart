import 'package:blogapp/Pages/IndividualPage.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ Secure Storage

class CustomCard extends StatelessWidget {
  final Map<String, dynamic> chat; // 🔥 Accept raw chat data from backend
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // ✅ Add secure storage

  CustomCard({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: storage.read(key: "email"), // ✅ Get current user's email from secure storage
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // Wait until we have email
        }

        final String? currentUserEmail = snapshot.data;
        final chatPartner = chat['users'].firstWhere(
                (user) => user['email'] != currentUserEmail,
            orElse: () => {'email': 'Unknown', 'username': 'Unknown'}
        );

        final chatPartnerName = chatPartner['username'] ?? 'Unknown User';
        final chatPartnerEmail = chatPartner['email'] ?? 'Unknown';
        final lastMessage = chat['lastMessage'] ?? 'No messages yet';
        final lastMessageTime = chat['lastMessageTime'] ?? ''; // You might want to format this

        return InkWell(
          onTap: () {
            // ⭐️ Change Navigation to IndividualPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualPage(
                  initialChatId: chat['_id'], // ✅ Pass chat ID
                  chatPartnerEmail: chatPartnerEmail, // ✅ Pass partner's email
                  chatPartnerName: chatPartnerName, // ✅ Pass partner's username
                ),
              ),
            );
          },
          child: Column(
            children: [
              ListTile(
                leading: ValueListenableBuilder<Color>(
                  valueListenable: appColorNotifier,
                  builder: (context, currentColor, child) {
                    return CircleAvatar(
                      radius: 30,
                      backgroundColor: currentColor,
                      child: Text(
                        chatPartnerName.isNotEmpty
                            ? chatPartnerName[0].toUpperCase()
                            : 'U', // ⭐️ Use the first letter of the partner's username
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        ),
                      ),
                    );
                  },
                ),
                title: Text(
                  chatPartnerName, // ⭐️ Use the partner's username instead of email
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.done_all, color: Colors.blue, size: 18),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  formatTime(lastMessageTime),
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

  String formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final DateTime dateTime = DateTime.parse(isoTime);
      return "${dateTime.hour}:${dateTime.minute}";
    } catch (e) {
      return '';
    }
  }
}
