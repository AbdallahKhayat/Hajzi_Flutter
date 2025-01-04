import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReplyCard extends StatelessWidget {
  final String message; // 🔥 New - Actual message
  final String time; // 🔥 New - Message timestamp
  final Color messageColor; // Background color for the message bubble
  final Color textColor; // Color for the text inside the message bubble

  const ReplyCard({
    super.key,
    required this.message,
    required this.time,
    required this.messageColor,
    required this.textColor
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 45,
        ),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: messageColor, // 🔥 Dynamic background color for the reply
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 60, top: 5, bottom: 12),
                child: Text(
                  message, // 🔥 Dynamic message text
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 10,
                child: Text(
                  time, // 🔥 Dynamic timestamp
                  style: TextStyle(fontSize: 11.2, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
