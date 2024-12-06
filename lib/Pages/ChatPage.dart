import 'package:flutter/material.dart';

import '../CustomWidget/CustomCard.dart';
import '../Models/ChatModel.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatModel> chats = [
    ChatModel(
      name: "Jack",
      isGroup: false,
      currentMessage: "Hi Jack!",
      time: "4:00",
      icon: Icons.person, // Updated to IconData
    ),
    ChatModel(
      name: "Friends Group",
      isGroup: true,
      currentMessage: "Hi everyone!",
      time: "6:00",
      icon: Icons.group, // Updated to IconData
    ),
    ChatModel(
      name: "Abdul",
      isGroup: false,
      currentMessage: "Hi Abdul!",
      time: "3:00",
      icon: Icons.person, // Updated to IconData
    ),
    ChatModel(
      name: "Salah",
      isGroup: false,
      currentMessage: "Hi Salah!",
      time: "7:00",
      icon: Icons.person, // Updated to IconData
    ),
    ChatModel(
      name: "Server Group",
      isGroup: true,
      currentMessage: "Hello from the server!",
      time: "10:00",
      icon: Icons.storage, // Updated to a more server-relevant IconData
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action when FAB is pressed
        },
        child: const Icon(Icons.chat),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) => CustomCard(chatModel: chats[index]),
      ),
    );
  }
}
