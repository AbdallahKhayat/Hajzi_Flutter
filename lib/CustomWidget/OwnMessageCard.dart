import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OwnMessageCard extends StatelessWidget {
  final Color messageColor; // Background color for the message bubble
  final Color textColor; // Color for the text inside the message bubble

  const OwnMessageCard({super.key, required this.messageColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 45,
        ),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: messageColor, // Switched: Background color is now dynamic
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 60, top: 5, bottom: 20),
                child: Text(
                  "Hey",
                  style: TextStyle(fontSize: 16, color: textColor), // Dynamic text color
                ),
              ),
              Positioned(
                bottom: 4,
                right: 10,
                child: Row(
                  children: [
                    Text(
                      "20:58",
                      style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)), // Slightly transparent
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.done_all,
                      size: 20,
                      color: Colors.grey, // Icon color
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
