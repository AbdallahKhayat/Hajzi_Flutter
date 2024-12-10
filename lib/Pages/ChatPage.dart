import 'package:flutter/material.dart';
import 'package:blogapp/CustomWidget/CustomCard.dart';
import 'package:blogapp/NetworkHandler.dart'; // 🔥 Import NetworkHandler
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔥 For JWT token

class ChatPage extends StatefulWidget {
  final String chatId; // 🔥 New parameter to receive chat ID
  final String chatPartnerEmail; // 🔥 New parameter to receive partner email

  const ChatPage({super.key, required this.chatId, required this.chatPartnerEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final NetworkHandler networkHandler = NetworkHandler(); // 🔥 Initialize NetworkHandler
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // 🔥 For JWT storage


  List<dynamic> chats = []; // 🔥 No longer using static list, this will be populated from the backend

  @override
  void initState() {
    super.initState();
    fetchChats(); // 🔥 Fetch chats from backend when the screen loads
  }

  /// 🔥 **Fetch Chats from Backend**
  Future<void> fetchChats() async {
    try {
      String? token = await storage.read(key: "token"); // 🔥 Get JWT token
      if (token == null) {
        print('No token found');
        return;
      }

      var response = await networkHandler.getWithAuth('/chat/user-chats', token); // 🔥 Fetch user chats
      if (response != null && response is List) {
        setState(() {
          chats = response; // 🔥 Update chats with the backend response
        });
      } else {
        print('Error fetching chats');
      }
    } catch (e) {
      print('Error in fetchChats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Handle new chat creation
        },
        child: const Icon(Icons.chat),
      ),
      body: chats.isEmpty
          ? const Center(child: CircularProgressIndicator()) // 🔥 Show a loading indicator while chats are being loaded
          : ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final String? currentUserEmail = 'CURRENT_USER_EMAIL_HERE'; // 🔥 Replace this with actual logged-in user's email
          final chatPartner = chat['users']
              .firstWhere((email) => email != currentUserEmail); // 🔥 Get the chat partner's email

          return CustomCard(
            chat: chat, // 🔥 Pass the raw chat data to CustomCard
          );
        },
      ),
    );
  }

  /// 🔥 **Helper method to format time from ISO to HH:MM**
  String formatTime(String? time) {
    if (time == null) return '';
    DateTime dateTime = DateTime.parse(time);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Format time as HH:MM
  }
}
