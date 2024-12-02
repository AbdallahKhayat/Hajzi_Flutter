import 'package:blogapp/Pages/ChatPage.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _controller;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = TabController(length: 4, vsync: this, initialIndex: 1);
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
              IconButton(icon: Icon(Icons.search), color: Colors.white, onPressed: () {}),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
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
            children: const [
              Text("Camera"),
              ChatPage(),
              Text("Status"),
              Text("Calls"),
            ],
          ),
        );
      },
    );
  }
}
