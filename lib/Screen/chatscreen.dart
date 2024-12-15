import 'package:blogapp/Screen/CameraFiles/CameraScreen.dart';
import 'package:blogapp/Pages/ChatPage.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔥 New import for secure storage
import 'package:blogapp/NetworkHandler.dart';

import '../Pages/SearchPage.dart'; // 🔥 Import NetworkHandler


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _controller;

  final storage = FlutterSecureStorage(); // 🔥 New secure storage instance
  NetworkHandler networkHandler = NetworkHandler(); // 🔥 Instance of NetworkHandler
  List<dynamic> chats = []; // 🔥 Store list of chats


  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this, initialIndex: 1);

    // 🔥 Fetch the list of chats when the screen loads
    fetchChats();

    // 🔥 Initialize the socket connection for real-time chat updates
    networkHandler.initSocketConnection();

    // 🔥 Listen for new incoming messages
    networkHandler.socket!.on('receive_message', (message) {
      print("🔥 New message received: $message");

      final chatId = message['chatId'];
      final messageContent = message['content'];

      setState(() {
        int chatIndex = chats.indexWhere((chat) => chat['_id'] == chatId);
        if (chatIndex != -1) {
          // Update last message and timestamp in the chat list
          chats[chatIndex]['lastMessage'] = messageContent;
          chats[chatIndex]['lastMessageTime'] = DateTime.now().toIso8601String();
        } else {
          // If it's a new chat, refresh the chats list
          fetchChats();
        }
      });
    });


    // Navigate to camera instantly if tab index is 0 (camera tab)
    _controller.addListener(() {
      if (_controller.index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      }
    });
  }

  // 🔥 Function to fetch user chats from the server
  Future<void> fetchChats() async {
    try {
      // 🔥 Get the token from secure storage
      String? token = await storage.read(key: "token");

      if (token != null) {
        var response = await networkHandler.getWithAuth('/chat/user-chats', token);

        if (response != null) {
          setState(() {
            chats = response; // 🔥 Store the list of chats in state
          });
          print("Chats loaded: $chats");
        } else {
          print("Failed to load chats.");
        }
      }
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier,
      builder: (context, appColor, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: appColor,
            title: const Text("Hajzi Chats", style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                  icon: const Icon(Icons.search),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(),
                      ),
                    ).then((_) {
                      fetchChats(); // 🔥 Refresh chat list when user returns from SearchPage
                    });
                  }
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {},
                itemBuilder: (BuildContext context) {
                  return const [
                    PopupMenuItem(value: "New group", child: Text("New group")),
                    PopupMenuItem(value: "New broadcast", child: Text("New broadcast")),
                    PopupMenuItem(value: "Hajzi web", child: Text("Hajzi web")),
                    PopupMenuItem(value: "Starred messages", child: Text("Starred messages")),
                    PopupMenuItem(value: "Settings", child: Text("Settings")),
                  ];
                },
              )
            ],
            bottom: TabBar(
              controller: _controller,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt)),
                Tab(text: "CHATS"),
                Tab(text: "STATUS"),
                Tab(text: "CALLS"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _controller,
            children: [
              const SizedBox.shrink(), // Empty widget for camera tab since camera opens automatically
              buildChatsList(), // 🔥 List of user chats
              const Center(child: Text("Status", style: TextStyle(fontSize: 18))),
              const Center(child: Text("Calls", style: TextStyle(fontSize: 18))),
            ],
          ),
        );
      },
    );
  }

  Widget buildChatsList() {
    if (chats.isEmpty) {
      return const Center(
        child: Text(
          'No chats available',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final chatPartner = chat['shopOwner']; // 🔥 Get shopOwner as chat partner
        final lastMessage = chat['lastMessage'] ?? 'No messages yet';
        final chatId = chat['_id']; // ⭐️ Extract chat ID
        final chatPartnerEmail = chat['shopOwner'] ?? 'Unknown'; // ⭐️ Extract the chat partner's email


        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal,
            child: Text(chatPartner != null && chatPartner.isNotEmpty
                ? chatPartner[0].toUpperCase()
                : 'U'),
          ),
          title: Text(chatPartner ?? 'Unknown User'),
          subtitle: Text(lastMessage),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  chatId: chatId, // ⭐️ Pass chat ID
                  chatPartnerEmail: chatPartnerEmail, // ⭐️ Pass partner's email
                ),
              ),
            );
          },
        );
      },
    );
  }


}
