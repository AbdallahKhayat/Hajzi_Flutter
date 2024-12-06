import 'dart:io';
import 'package:flutter/material.dart';
import '../constants.dart';

class CameraViewPage extends StatelessWidget {
  const CameraViewPage({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.crop_rotate, size: 28),
            tooltip: "Crop & Rotate",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions_outlined, size: 28),
            tooltip: "Add Emoji",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.title, size: 28),
            tooltip: "Add Text",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 28),
            tooltip: "Edit Image",
          ),
        ],
      ),
      body: Stack(
        children: [
          // Adjust the image to occupy more vertical space
          Align(
            alignment: Alignment.topCenter,
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.8, // Occupy 80% of the screen
            ),
          ),
          // Caption and send section at the bottom
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Row(
                children: [
                  // Caption input field
                  Expanded(
                    child: TextFormField(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 6,
                      minLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Add Caption...",
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send/Check button with appColorNotifier
                  ValueListenableBuilder<Color>(
                    valueListenable: appColorNotifier,
                    builder: (context, appColor, _) {
                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: appColor,
                        child: IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            // Add functionality for send action
                          },
                          tooltip: "Send",
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
