import 'package:blogapp/Pages/IndividualPage.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // For time formatting

class CustomCard extends StatelessWidget {
  final Map<String, dynamic> chat;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  CustomCard({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: storage.read(key: "email"),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final String? currentUserEmail = snapshot.data;
        final chatPartner = chat['users'].firstWhere(
                (user) => user['email'] != currentUserEmail,
            orElse: () => {'email': 'Unknown', 'username': 'Unknown'}
        );

        final chatPartnerName = chatPartner['username'] ?? 'Unknown User';
        final chatPartnerEmail = chatPartner['email'] ?? 'Unknown';
        final lastMessage = chat['lastMessage'] ?? 'No messages yet';
        final lastMessageTime = chat['lastMessageTime'] ?? '';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualPage(
                  initialChatId: chat['_id'],
                  chatPartnerEmail: chatPartnerEmail,
                  chatPartnerName: chatPartnerName,
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
                            : 'U',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
