// mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'ChatBotScreen.dart';


class ModeSelectionScreen extends StatelessWidget {
  final String userEmail;
  final Function(Locale) setLocale;

  ModeSelectionScreen({required this.userEmail, required this.setLocale});

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
                      setLocale: setLocale,
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
                      setLocale: setLocale,
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
