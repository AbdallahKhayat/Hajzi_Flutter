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
    return Scaffold(
      appBar: AppBar(
        title: Text("Hajzi Chats"),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {},),
          PopupMenuButton<String>(
              onSelected: (value){
               // print(value);
              },
              itemBuilder: (BuildContext context){
            return [
              PopupMenuItem(child: Text("New group"), value: "New group",),
              PopupMenuItem(child: Text("New broadcast"), value: "New broadcast",),
              PopupMenuItem(child: Text("Hajzi web"), value: "Hajzi web",),
              PopupMenuItem(child: Text("Starred messages"), value: "Starred messages",),
              PopupMenuItem(child: Text("Settings"), value: "Settings",),
            ];
          })
        ],
        bottom: TabBar(
          controller: _controller,
          indicatorColor: appColor,
          tabs: [
            Tab(
              icon: Icon(Icons.camera_alt),
            ),
            Tab(
              text: "CHATS",
            ),
            Tab(
              text: "STATUS",
            ),
            Tab(text: "CALLS",),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
        Text("Camera"),
        ChatPage(),
        Text("Status"),
        Text("Calls"),
      ],),
    );
  }
}
