import 'package:blogapp/Pages/IndividualPage.dart';
import 'package:flutter/material.dart';

import '../Models/ChatModel.dart';
import '../constants.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({super.key, required this.chatModel});

  final ChatModel chatModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => IndividualPage(
                      chatModel: chatModel,
                    )));
      },
      child: Column(
        children: [
          ListTile(
            leading: ValueListenableBuilder<Color>(
              valueListenable: appColorNotifier, // Correct usage
              builder: (context, currentColor, child) {
                return CircleAvatar(
                  radius: 30,
                  backgroundColor: currentColor,
                  child: Icon(
                    chatModel.icon, // Use dynamic icon from the model
                    color: Colors.white,
                    size: 37,
                  ),
                );
              },
            ),
            title: Text(
              chatModel.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.done_all),
                const SizedBox(width: 3),
                Text(
                  chatModel.currentMessage,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            trailing: Text(chatModel.time),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }
}
