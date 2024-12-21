// mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'ChatBotScreen.dart';


class ModeSelectionScreen extends StatelessWidget {
  final String userEmail;

  ModeSelectionScreen({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Interaction Mode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text('Chat with AI'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatBotScreen(
                      userEmail: userEmail,
                      isAIModeInitial: true,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Hajzi Predefined Questions'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatBotScreen(
                      userEmail: userEmail,
                      isAIModeInitial: false,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
