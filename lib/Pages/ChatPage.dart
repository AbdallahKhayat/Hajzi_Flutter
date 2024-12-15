import 'package:flutter/material.dart';
import 'package:blogapp/CustomWidget/CustomCard.dart'; // 🔥 Use CustomCard
import 'package:blogapp/NetworkHandler.dart'; // 🔥 Import NetworkHandler
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔥 For JWT token

class ChatPage extends StatefulWidget {
  final String chatId; // ⭐️ New parameter for chat ID
  final String chatPartnerEmail; // ⭐️ New parameter for chat partner email

  const ChatPage({super.key,required this.chatId,required this.chatPartnerEmail}); // 🔥 Remove chatId and chatPartnerEmail parameters

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final NetworkHandler networkHandler = NetworkHandler(); // 🔥 Initialize NetworkHandler
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // 🔥 For JWT storage

  List<dynamic> chats = []; // 🔥 Store chats fetched from the backend

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

      var response = await networkHandler.getWithAuth('/chat/user-chats', token);
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
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: chats.isEmpty
          ? const Center(
        child: Text(
          'No chats available',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return CustomCard(chat: chat); // ⭐️ Only pass the 'chat' object to CustomCard
        },
      ),
    );
  }
}
