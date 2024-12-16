import 'package:flutter/material.dart';
import 'package:blogapp/CustomWidget/CustomCard.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String chatPartnerEmail;

  const ChatPage({super.key, required this.chatId, required this.chatPartnerEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final NetworkHandler networkHandler = NetworkHandler();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    // Ensure socket is initialized before fetching chats
    // If not, call NetworkHandler().initSocketConnection(); at app start.
    fetchChats().then((_) {
      setupSocketListeners();
    });
  }

  Future<void> fetchChats() async {
    try {
      String? token = await storage.read(key: "token");
      if (token == null) {
        print('No token found');
        return;
      }

      var response = await networkHandler.getWithAuth('/chat/user-chats', token);
      if (response != null && response is List) {
        setState(() {
          chats = response;
        });

        // Join all chat rooms after fetching chats
        if (NetworkHandler().socket != null && NetworkHandler().socket!.connected) {
          for (var c in chats) {
            NetworkHandler().socket!.emit('join_chat', c['_id']);
          }
        } else {
          print("⚠️ Socket not connected yet. Will need to join later on connect event.");
        }

      } else {
        print('Error fetching chats');
      }
    } catch (e) {
      print('Error in fetchChats: $e');
    }
  }

  void setupSocketListeners() {
    if (NetworkHandler().socket != null) {
      // Remove old listener to avoid duplicates
      NetworkHandler().socket!.off('receive_message_chatpage'); // optional if needed once

      NetworkHandler().socket!.on('receive_message_chatpage', (data) {
        print("🔔 ChatPage event: $data");
        final updatedChatId = data['chatId'];

        if (updatedChatId == null) {
          print("❌ No chatId in received message data");
          return;
        }

        final index = chats.indexWhere((chat) => chat['_id'] == updatedChatId);
        if (index != -1) {
          // Chat found, move it to top and update last message/time
          setState(() {
            final updatedChat = chats.removeAt(index);
            updatedChat['lastMessage'] = data['content'];
            updatedChat['lastMessageTime'] = DateTime.now().toIso8601String();
            chats.insert(0, updatedChat);
          });
        } else {
          // Chat not found, refetch chats (optional)
          fetchChats();
        }
      });

      // Optionally handle the socket connect event to rejoin rooms if needed:
      NetworkHandler().socket!.on('connect', (_) {
        print("✅ Socket connected in ChatPage.");
        for (var c in chats) {
          NetworkHandler().socket!.emit('join_chat', c['_id']);
        }
      });
    } else {
      print("⚠️ Socket not initialized in ChatPage. Cannot listen to events.");
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
          : FutureBuilder<String?>(
        future: storage.read(key: "email"),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final currentUserEmail = snapshot.data;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatPartner = (chat['users'] as List)
                  .firstWhere((user) => user['email'] != currentUserEmail, orElse: () => null);

              if (chatPartner != null) {
                return CustomCard(chat: {
                  ...chat,
                  'chatPartnerEmail': chatPartner['email'],
                  'chatPartnerName': chatPartner['username'],
                });
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }
}
