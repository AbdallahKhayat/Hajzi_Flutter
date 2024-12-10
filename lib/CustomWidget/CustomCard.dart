import 'package:blogapp/Pages/IndividualPage.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

class CustomCard extends StatelessWidget {
  final Map<String, dynamic> chat; // 🔥 Accept raw chat data from backend

  const CustomCard({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    // Extract chat data
    final String chatPartnerEmail = chat['users']
        .firstWhere((email) => email != 'CURRENT_USER_EMAIL_HERE'); // 🔥 Get the email of the other user
    final String lastMessage = chat['lastMessage'] ?? 'No messages yet';
    final String time = _formatTime(chat['lastMessageTime']);
    final String partnerInitial = chatPartnerEmail.isNotEmpty
        ? chatPartnerEmail[0].toUpperCase()
        : '?'; // 🔥 Extract first letter of the chat partner's email

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualPage(
              chatId: chat['_id'], // 🔥 Pass chatId
              chatPartnerEmail: chatPartnerEmail, // 🔥 Pass partner's email
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
                    partnerInitial, // 🔥 Dynamic first letter of partner's email
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
              chatPartnerEmail, // 🔥 Dynamic chat partner's email as the chat title
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
            trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)), // 🔥 Dynamic time
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }

  /// 🔥 **Utility function to format the time from ISO string**
  String _formatTime(String? isoTime) {
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
      return ''; // Return empty string if there is an error parsing
    }
  }
}
