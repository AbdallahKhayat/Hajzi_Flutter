import 'package:blogapp/Pages/IndividualPage.dart';
import 'package:flutter/material.dart';
import '../constants.dart';


class CustomCard extends StatelessWidget {
  final Map<String, dynamic> chat; // 🔥 Accept raw chat data from backend

  const CustomCard({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    // Extract chat data
    final String currentUserEmail = 'CURRENT_USER_EMAIL_HERE'; // Replace with actual user email
    final chatPartner = chat['users'].firstWhere((user) => user['email'] != currentUserEmail); // Get chat partner details
    final chatPartnerName = chatPartner['username'] ?? 'Unknown User'; // ⭐️ Extract the username from the 'chat' object
    final chatPartnerEmail = chatPartner['email'];
    final lastMessage = chat['lastMessage'] ?? 'No messages yet';
    final lastMessageTime = chat['lastMessageTime'] ?? ''; // You might want to format this

    return InkWell(
      onTap: () {
        // ⭐️ Change Navigation to IndividualPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualPage(
              initialChatId: chat['_id'], // ⭐️ Pass chat ID
              chatPartnerEmail: chatPartner['email'], // ⭐️ Pass partner's email
              chatPartnerName: chatPartner['username'] ?? 'Unknown', // ⭐️ Pass partner's username
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
                    chatPartnerName.isNotEmpty ? chatPartnerName[0].toUpperCase() : 'U', // ⭐️ Use the first letter of the partner's username
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
                const Icon(Icons.done_all, color: Colors.blue, size: 18), // ✅ Read/Delivered Status
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
            ),// 🔥 Dynamic time
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }

  // ⭐️ Utility Function for Time Formatting
  String formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final DateTime dateTime = DateTime.parse(isoTime);
      final Duration difference = DateTime.now().difference(dateTime);
      if (difference.inDays > 0) {
        return "${dateTime.day}/${dateTime.month}";
      } else {
        return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      return '';
    }
  }
}
