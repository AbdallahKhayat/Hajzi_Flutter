// CustomCard.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import '../Pages/IndividualPage.dart';
import '../constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class CustomCard extends StatelessWidget {
  final Map<String, dynamic> chat;
  final String currentUserEmail;
  final NetworkHandler networkHandler = NetworkHandler();
  final void Function(Map<String, dynamic>)? onChatSelected;
  final int chatFlag;
  CustomCard({
    Key? key,
    required this.chat,
    required this.currentUserEmail,
    required this.chatFlag,
    this.onChatSelected
  }) : super(key: key);

  Future<String?> fetchProfileImage(String chatPartnerEmail) async {
    try {
      final storage = FlutterSecureStorage();
      String? token = await storage.read(key: "token");
      if (token == null) {
        print('No token found');
        return null;
      }

      final response = await networkHandler
          .get('/profile/getDataByEmail?email=$chatPartnerEmail');

      if (response != null && response.containsKey('data')) {
        String? imgPath = response['data']['img'];
        if (imgPath != null && imgPath.isNotEmpty) {
          // Append a timestamp to bust the cache
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          return 'https://hajzi-6883b1f029cf.herokuapp.com/' +
              imgPath +
              '?v=$timestamp';
        }
      } else {
        print('Error fetching profile data');
      }
    } catch (e) {
      print('Error in fetchProfileImage: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chatPartner = chat['chatPartnerEmail'] != null
        ? {
            'email': chat['chatPartnerEmail'],
            'username': chat['chatPartnerName'],
          }
        : {'email': 'Unknown', 'username': 'Unknown'};

    final chatPartnerName = chatPartner['username'] ?? 'Unknown User';
    final chatPartnerEmail = chatPartner['email'] ?? 'Unknown';
    final lastMessage = chat['lastMessage'] ?? 'No messages yet';
    final lastMessageTime = chat['lastMessageTime'] ?? '';

    return FutureBuilder<String?>(
      future: fetchProfileImage(chatPartnerEmail),
      builder: (context, snapshot) {
        String? profileImageUrl = snapshot.data;

        return InkWell(
          onTap: () {

            if(kIsWeb) {
              // Instead, call the parent callback if provided.
              if (onChatSelected != null) {
                onChatSelected!(chat);
              }
              if(chatFlag == 1){
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
              }
            }else
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
                leading: profileImageUrl != null
                    ? CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            CachedNetworkImageProvider(profileImageUrl),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
