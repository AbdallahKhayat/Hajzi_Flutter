import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReplyCard extends StatelessWidget {
  final String message; // 🔥 New - Actual message
  final String time; // 🔥 New - Message timestamp
  final Color messageColor; // Background color for the message bubble
  final Color textColor; // Color for the text inside the message bubble
  final VoidCallback onLongPress; // Added callback

  const ReplyCard({
    super.key,
    required this.message,
    required this.time,
    required this.messageColor,
    required this.textColor,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress, // Handle long press
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 45,
          ),
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: messageColor,
            // 🔥 Dynamic background color for the reply
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 60, top: 5, bottom: 20),
                  child: Text(
                    message, // 🔥 Dynamic message text
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 10,
                  child: Text(
                    time, // 🔥 Dynamic timestamp
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
