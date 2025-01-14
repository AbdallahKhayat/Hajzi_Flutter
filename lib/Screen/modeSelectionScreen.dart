// mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'ChatBotScreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ModeSelectionScreen extends StatelessWidget {
  final String userEmail;
  final Function(Locale) setLocale;

  ModeSelectionScreen({required this.userEmail, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chooseMode),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.aiMode),
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
              child: Text(AppLocalizations.of(context)!.predefinedMode1),
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
